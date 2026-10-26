import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_viewer_pro/pdf_viewer_pro.dart';
import 'package:pdf_viewer_pro/src/core/platform_utils.dart';

void main() {
  test('browsers never select native iOS or Android behavior', () {
    for (final target in TargetPlatform.values) {
      expect(
        ViewerPlatform.isNative(TargetPlatform.iOS,
            isWeb: true, targetPlatform: target),
        isFalse,
      );
      expect(
        ViewerPlatform.isNative(TargetPlatform.android,
            isWeb: true, targetPlatform: target),
        isFalse,
      );
    }
  });

  test('native platform selection preserves iOS and Android behavior', () {
    for (final target in TargetPlatform.values) {
      expect(
        ViewerPlatform.isNative(TargetPlatform.iOS,
            isWeb: false, targetPlatform: target),
        target == TargetPlatform.iOS,
      );
      expect(
        ViewerPlatform.isNative(TargetPlatform.android,
            isWeb: false, targetPlatform: target),
        target == TargetPlatform.android,
      );
    }
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('native DRM channels remain active on $platform',
        (tester) async {
      const channel = MethodChannel('screen_protector');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (call) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));

      // With no source, initialization finishes without network or PDFium.
      final controller = PdfReaderController(title: 'DRM platform check');
      controller.initialize();
      await tester.pump();
      expect(
        calls,
        platform == TargetPlatform.iOS
            ? ['preventScreenshotOn', 'protectDataLeakageWithBlur']
            : ['protectDataLeakageOn'],
      );
      calls.clear();
      controller.dispose();
      await tester.pump();
      expect(
        calls,
        platform == TargetPlatform.iOS
            ? ['preventScreenshotOff', 'protectDataLeakageWithBlurOff']
            : ['protectDataLeakageOff'],
      );
    }, variant: TargetPlatformVariant.only(platform));

    testWidgets('reader controls and dialogs adapt safely to $platform',
        (tester) async {
      final isIOS = platform == TargetPlatform.iOS;
      final controller = PdfReaderController(title: 'Platform controls');
      controller.totalPages.value = 10;

      expect(ViewerIcons.back, isIOS ? CupertinoIcons.back : Icons.arrow_back);
      expect(ViewerIcons.search, isIOS ? CupertinoIcons.search : Icons.search);
      expect(iosScrollPhysics(),
          isIOS ? isA<BouncingScrollPhysics>() : isA<ClampingScrollPhysics>());

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          drawer: PdfThumbnailsDrawer(controller: controller),
          body: Column(children: [
            PdfReaderTopBar(
              controller: controller,
              onBack: () {},
              onOpenThumbnails: () {},
              onOpenBookmarks: () {},
              onOpenSettings: () {},
              onSearch: () {},
            ),
            PdfReaderBottomBar(
              controller: controller,
              onPrevPage: () {},
              onNextPage: () {},
              onToggleScrollDirection: () {},
              onGoToPage: () {},
            ),
            Builder(builder: (context) {
              return TextButton(
                onPressed: () => showViewerDialog<void>(
                  context: context,
                  title: 'Reader dialog',
                  content: const Text('Content'),
                  actions: const [],
                ),
                child: const Text('Open dialog'),
              );
            }),
          ]),
        ),
      ));

      expect(find.byTooltip('Pages'), findsOneWidget);
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(
          find.byType(CupertinoSlider), isIOS ? findsOneWidget : findsNothing);
      expect(find.byType(Slider), isIOS ? findsNothing : findsOneWidget);
      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog),
          isIOS ? findsOneWidget : findsNothing);
      expect(find.byType(AlertDialog), isIOS ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(platform));
  }
}
