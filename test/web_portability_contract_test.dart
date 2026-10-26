import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

late Uri _sourceRoot;

String _read(String path) =>
    File.fromUri(_sourceRoot.resolve(path)).readAsStringSync();

void main() {
  setUpAll(() {
    // The plugin tests may run from either the plugin or the consuming app.
    // Flutter's test VM does not support Isolate.resolvePackageUri.
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config =
        jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
    final packages = config['packages'] as List<dynamic>;
    final package = packages.cast<Map<String, dynamic>>().firstWhere(
      (package) => package['name'] == 'pdf_viewer_pro',
    );
    final root = package['rootUri'] as String;
    _sourceRoot = configFile.uri
        .resolve(root.endsWith('/') ? root : '$root/')
        .resolve(package['packageUri'] as String? ?? 'lib/')
        .resolve('src/');
  });

  test('viewer UI and platform helpers never call dart:io Platform', () {
    final sources = [
      File.fromUri(_sourceRoot.resolve('core/platform_utils.dart')),
      ...Directory.fromUri(_sourceRoot.resolve('viewer/'))
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
    ];
    for (final file in sources) {
      final source = file.readAsStringSync();
      expect(source, isNot(matches(r'\bPlatform\.')), reason: file.path);
      if (!file.path.endsWith('pdf_reader_controller.dart')) {
        expect(source, isNot(contains('dart:io')), reason: file.path);
      }
    }
  });

  test(
    'web controller branch bypasses all native file and cache operations',
    () {
      final controller = _read('viewer/pdf_reader_controller.dart');
      final webStart = controller.indexOf('if (kIsWeb)');
      final nativeStart = controller.indexOf('} else if (isUrl)', webStart);
      expect(webStart, greaterThan(0));
      expect(nativeStart, greaterThan(webStart));
      final web = controller.substring(webStart, nativeStart);
      expect(web, contains('loadWebPdfDocument('));
      expect(web, contains('headers: serviceConfig.httpHeaders'));
      expect(web, contains('localFilePath.value = null'));
      for (final forbidden in [
        'File(',
        'openFile(',
        'openUri(',
        '_downloadFileWithHeaders(',
        'getTemporaryDirectory(',
      ]) {
        expect(web, isNot(contains(forbidden)));
      }
      final loader = _read('core/pdf_web_loader.dart');
      expect(loader, contains('PdfDocument.openData('));
      expect(loader, isNot(contains('dart:io')));
      expect(loader, isNot(contains('path_provider')));
    },
  );

  test(
    'web rendering reuses the authenticated document without another URL load',
    () {
      final screen = _read('viewer/pdf_viewer_screen.dart');
      final start = screen.indexOf('child: kIsWeb || isLocalPath');
      final end = screen.indexOf(': PdfViewer.uri(', start);
      expect(start, greaterThan(0));
      expect(end, greaterThan(start));
      final sharedViewer = screen.substring(start, end);
      expect(
        sharedViewer,
        contains('PdfDocumentRefDirect(_controller.pdfDocument!'),
      );
      expect(sharedViewer, contains('autoDispose: false'));
      expect(sharedViewer, isNot(contains('PdfViewer.uri(')));
    },
  );

  test('screen DRM hooks explicitly skip native channels on web', () {
    final screen = _read('viewer/pdf_viewer_screen.dart');
    for (final method in ['_setupDrm', '_teardownDrm']) {
      final start = screen.indexOf('Future<void> $method()');
      expect(start, greaterThan(0));
      final guard = screen.indexOf('if (!kIsWeb && widget.enableDrm)', start);
      final channelCall = screen.indexOf('await ScreenProtector.', start);
      expect(guard, greaterThan(start));
      expect(guard, lessThan(channelCall));
    }
  });
}
