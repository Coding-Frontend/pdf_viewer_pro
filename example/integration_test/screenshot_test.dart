import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pdf_viewer_pro_example/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pdf example screenshots', (WidgetTester tester) async {
    app.main();
    // wait for app to settle
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Home screen
    await binding.takeScreenshot('pdf_home');

    // Try open from URL (uses sample PDF)
    final openFromUrl = find.text('Open from URL');
    if (openFromUrl.evaluate().isNotEmpty) {
      await tester.tap(openFromUrl);
      await tester.pumpAndSettle(const Duration(seconds: 6));
      // reader
      await binding.takeScreenshot('pdf_reader');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      // open thumbnails if available (best-effort by finding 'Thumbnails' label)
      final thumbnailsToggle = find.text('Thumbnails');
      if (thumbnailsToggle.evaluate().isNotEmpty) {
        await tester.tap(thumbnailsToggle);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await binding.takeScreenshot('pdf_thumbnails');
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
      // back to home
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('pdf_after_reader');
    }
  });
}
