import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_viewer_pro/pdf_viewer_pro.dart';

void main() {
  testWidgets('PDF bottom bar exposes Chrome-style reader controls',
      (tester) async {
    final controller = PdfReaderController(title: 'Reader controls');
    controller.currentPage.value = 3;
    controller.totalPages.value = 10;
    controller.progress.value = 0.3;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: PdfReaderBottomBar(
              controller: controller,
              onPrevPage: () {},
              onNextPage: () {},
              onToggleScrollDirection: () {},
              onGoToPage: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Fit page'), findsOneWidget);
    expect(find.byTooltip('Fit width'), findsOneWidget);
    expect(find.byTooltip('Fit height'), findsOneWidget);
    expect(find.byTooltip('Rotate clockwise (0°)'), findsOneWidget);
    expect(find.text('/10'), findsOneWidget);

    await tester.tap(find.byTooltip('Fit width'));
    await tester.pump();
    expect(controller.fitMode.value, PdfFitMode.width);

    await tester.tap(find.byTooltip('Rotate clockwise (0°)'));
    await tester.pump();
    expect(controller.rotationQuarterTurns.value, 1);
    expect(find.byTooltip('Rotate clockwise (90°)'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });
}
