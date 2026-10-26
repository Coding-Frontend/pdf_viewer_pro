import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';

int _nextDocumentId = 0;

/// Fetches the original public or protected URL and renders its bytes via
/// pdfrx's web implementation. No local file or persistent plugin cache is used.
Future<PdfDocument> loadWebPdfDocument(
  String source, {
  Map<String, String>? headers,
  void Function(int received, int total)? onProgress,
}) async {
  final uri = Uri.parse(source);
  if ((uri.scheme != 'https' && uri.scheme != 'http') || uri.host.isEmpty) {
    throw UnsupportedError('The web PDF reader requires an HTTP(S) URL.');
  }

  onProgress?.call(0, 0);
  final client = http.Client();
  try {
    final request = http.Request('GET', uri);
    if (headers != null) request.headers.addAll(headers);
    request.headers['Accept'] = 'application/pdf';
    final response = await client.send(request);

    // Never retry a protected request without its credentials or at another URL.
    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        throw Exception(
            'Authentication required. Please check your credentials.');
      case 403:
        throw Exception('Access denied. You may not have purchased this book.');
      case 404:
        throw Exception('PDF file not found on server.');
      default:
        throw Exception('Download failed with status ${response.statusCode}');
    }

    final contentType = (response.headers['content-type'] ?? '').toLowerCase();
    if (contentType.contains('json') || contentType.contains('text/html')) {
      throw Exception('Server returned an error instead of a PDF file.');
    }

    final total = response.contentLength ?? 0;
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      bytes.add(chunk);
      onProgress?.call(bytes.length, total);
    }
    if (bytes.isEmpty) throw Exception('Server returned an empty PDF file.');

    // Distinct names prevent pdfrx sharing a reference between different books;
    // a neutral name also avoids retaining a signed URL in document metadata.
    return await PdfDocument.openData(
      bytes.takeBytes(),
      sourceName: 'memory:pdf-${_nextDocumentId++}',
    );
  } finally {
    client.close();
  }
}
