import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pdf_viewer_pro/src/core/pdf_web_loader.dart';
import 'package:pdfrx/pdfrx.dart';

class _Document extends Fake implements PdfDocument {}

class _MemoryFactory extends Fake implements PdfDocumentFactory {
  final documents = <PdfDocument>[];
  final data = <Uint8List>[];
  final names = <String?>[];
  Object? failure;

  @override
  Future<PdfDocument> openData(
    Uint8List bytes, {
    PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
    String? sourceName,
    bool allowDataOwnershipTransfer = false,
    void Function()? onDispose,
  }) async {
    data.add(bytes);
    names.add(sourceName);
    if (failure != null) throw failure!;
    final document = _Document();
    documents.add(document);
    return document;
  }
}

class _Client extends MockClient {
  _Client(super.handler);
  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  late PdfDocumentFactory originalFactory;
  late _MemoryFactory factory;
  final bytes = Uint8List.fromList('%PDF-1.7\nfixture'.codeUnits);
  const url = 'https://reader.invalid/api/files/42/read';

  setUp(() {
    originalFactory = PdfDocumentFactory.instance;
    factory = _MemoryFactory();
    PdfDocumentFactory.instance = factory;
  });

  tearDown(() => PdfDocumentFactory.instance = originalFactory);

  for (final protected in [false, true]) {
    test('${protected ? 'JWT PDF' : 'public sample'} opens original bytes once',
        () async {
      final headers = protected
          ? {'Authorization': 'Bearer test-jwt', 'X-Reader': 'test'}
          : null;
      final requests = <http.Request>[];
      final client = _Client((request) async {
        requests.add(request);
        return http.Response.bytes(bytes, 200,
            headers: {'content-type': 'application/pdf'});
      });
      final progress = <(int, int)>[];

      final document = await http.runWithClient(
        () => loadWebPdfDocument(url,
            headers: headers,
            onProgress: (received, total) => progress.add((received, total))),
        () => client,
      );

      expect(document, same(factory.documents.single));
      expect(factory.data.single, orderedEquals(bytes));
      expect(factory.names.single, startsWith('memory:pdf-'));
      expect(requests.single.url.toString(), url);
      expect(requests.single.method, 'GET');
      expect(requests.single.headers['Accept'], 'application/pdf');
      expect(requests.single.headers['Authorization'],
          protected ? 'Bearer test-jwt' : isNull);
      expect(requests.single.headers['X-Reader'], protected ? 'test' : isNull);
      expect(
          headers,
          protected
              ? containsPair('Authorization', 'Bearer test-jwt')
              : isNull);
      expect(progress.first, (0, 0));
      expect(progress.last, (bytes.length, bytes.length));
      expect(client.closed, isTrue);
    });
  }

  test('different loads have distinct document reference identities', () async {
    for (var i = 0; i < 2; i++) {
      await http.runWithClient(
        () => loadWebPdfDocument(url),
        () => _Client((_) async => http.Response.bytes(bytes, 200)),
      );
    }
    expect(factory.names.toSet(), hasLength(2));
  });

  test('streamed download reports progress when length is unknown', () async {
    final progress = <(int, int)>[];
    await http.runWithClient(
      () => loadWebPdfDocument(url,
          onProgress: (received, total) => progress.add((received, total))),
      () => MockClient.streaming((_, __) async => http.StreamedResponse(
            Stream.fromIterable([bytes.sublist(0, 5), bytes.sublist(5)]),
            200,
          )),
    );
    expect(progress, [(0, 0), (5, 0), (bytes.length, 0)]);
    expect(factory.data.single, orderedEquals(bytes));
  });

  for (final (status, message) in [
    (401, 'Authentication required'),
    (403, 'Access denied'),
    (404, 'PDF file not found'),
    (500, 'Download failed with status 500'),
    (206, 'Download failed with status 206'),
  ]) {
    test('HTTP $status fails without rendering or anonymous retry', () async {
      var requests = 0;
      final client = _Client((request) async {
        requests++;
        expect(request.headers['Authorization'], 'Bearer test-jwt');
        return http.Response('server error', status);
      });
      await expectLater(
        http.runWithClient(
          () => loadWebPdfDocument(url,
              headers: {'Authorization': 'Bearer test-jwt'}),
          () => client,
        ),
        throwsA(predicate((e) => e.toString().contains(message))),
      );
      expect(requests, 1);
      expect(factory.data, isEmpty);
      expect(client.closed, isTrue);
    });
  }

  for (final contentType in [
    'application/json',
    'application/problem+json',
    'text/html; charset=UTF-8',
  ]) {
    test('rejects $contentType even with HTTP 200', () async {
      await expectLater(
        http.runWithClient(
          () => loadWebPdfDocument(url),
          () => _Client((_) async => http.Response('error', 200,
              headers: {'content-type': contentType})),
        ),
        throwsException,
      );
      expect(factory.data, isEmpty);
    });
  }

  test('empty success response is rejected before rendering', () async {
    await expectLater(
      http.runWithClient(
        () => loadWebPdfDocument(url),
        () => _Client((_) async => http.Response('', 200)),
      ),
      throwsException,
    );
    expect(factory.data, isEmpty);
  });

  test('renderer failures close the client and propagate', () async {
    factory.failure = StateError('invalid PDF');
    final client = _Client((_) async => http.Response.bytes(bytes, 200));
    await expectLater(
      http.runWithClient(() => loadWebPdfDocument(url), () => client),
      throwsStateError,
    );
    expect(client.closed, isTrue);
  });

  test('transport failures close the client without a fallback request',
      () async {
    var requests = 0;
    final client = _Client((_) async {
      requests++;
      throw http.ClientException('CORS/network failure');
    });
    await expectLater(
      http.runWithClient(() => loadWebPdfDocument(url), () => client),
      throwsA(isA<http.ClientException>()),
    );
    expect(requests, 1);
    expect(factory.data, isEmpty);
    expect(client.closed, isTrue);
  });

  test('native paths are rejected before creating an HTTP client', () async {
    for (final path in ['/tmp/private.pdf', 'file:///tmp/private.pdf']) {
      await expectLater(
        http.runWithClient(
          () => loadWebPdfDocument(path),
          () => throw StateError('must not create a client'),
        ),
        throwsUnsupportedError,
      );
    }
  });
}
