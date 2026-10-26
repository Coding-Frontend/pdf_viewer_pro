import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_viewer_pro/pdf_viewer_pro.dart';
import 'package:pdfrx/pdfrx.dart' as engine;

class _Text extends engine.PdfPageText {
  _Text(this.pageNumber, this.fullText);
  @override
  final int pageNumber;
  @override
  final String fullText;
  @override
  late final fragments = [
    engine.PdfPageTextFragment.fromParams(
      0,
      fullText.length,
      engine.PdfRect(20, 720, 20 + fullText.length * 8, 700),
      fullText,
      List.generate(
        fullText.length,
        (i) => engine.PdfRect(20 + i * 8, 720, 28 + i * 8, 700),
      ),
    ),
  ];
}

class _Cancellation extends engine.PdfPageRenderCancellationToken {
  @override
  bool isCanceled = false;
  @override
  void cancel() => isCanceled = true;
}

class _Page extends engine.PdfPage {
  _Page(this.document, this.pageNumber, this.text);
  @override
  final _Document document;
  @override
  final int pageNumber;
  final String text;
  @override
  double get width => 600;
  @override
  double get height => 800;
  @override
  bool get isLoaded => true;
  @override
  engine.PdfPageRotation get rotation => engine.PdfPageRotation.none;
  @override
  engine.PdfPageRenderCancellationToken createCancellationToken() =>
      _Cancellation();
  @override
  Future<engine.PdfImage?> render({
    int x = 0,
    int y = 0,
    int? width,
    int? height,
    double? fullWidth,
    double? fullHeight,
    Color? backgroundColor,
    engine.PdfAnnotationRenderingMode annotationRenderingMode =
        engine.PdfAnnotationRenderingMode.annotationAndForms,
    int flags = engine.PdfPageRenderFlags.none,
    engine.PdfPageRenderCancellationToken? cancellationToken,
  }) async => null;
  @override
  Future<List<engine.PdfLink>> loadLinks({
    bool compact = false,
    bool enableAutoLinkDetection = true,
  }) async => [];
  @override
  Future<engine.PdfPageText> loadText() async {
    if (pageNumber == 2) await document.textGate?.future;
    return _Text(pageNumber, text);
  }
}

class _Document extends engine.PdfDocument {
  _Document(String name) : super(sourceName: name);
  Completer<void>? textGate;
  int disposals = 0;
  @override
  late final List<engine.PdfPage> pages = [
    _Page(this, 1, 'Chapter One'),
    _Page(this, 2, 'Chapter Two'),
  ];
  @override
  engine.PdfPermissions? get permissions => null;
  @override
  bool get isEncrypted => false;
  @override
  Stream<engine.PdfDocumentEvent> get events => const Stream.empty();
  @override
  Future<void> dispose() async {
    disposals++;
  }

  @override
  Future<List<engine.PdfOutlineNode>> loadOutline() async => [];
  @override
  bool isIdenticalDocumentHandle(Object? other) => identical(this, other);
  @override
  Future<void> loadPagesProgressively<T>({
    engine.PdfPageLoadingCallback<T>? onPageLoadProgress,
    T? data,
    Duration loadUnitDuration = const Duration(milliseconds: 250),
  }) async {}
}

class _Factory extends Fake implements engine.PdfDocumentFactory {
  _Factory(this.document);
  final _Document document;
  int opens = 0;
  @override
  Future<engine.PdfDocument> openUri(
    Uri uri, {
    engine.PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
    engine.PdfDownloadProgressCallback? progressCallback,
    bool preferRangeAccess = false,
    Map<String, String>? headers,
    bool withCredentials = false,
  }) async {
    opens++;
    return document;
  }

  @override
  Future<engine.PdfDocument> openData(
    Uint8List data, {
    engine.PdfPasswordProvider? passwordProvider,
    bool firstAttemptByEmptyPassword = true,
    bool useProgressiveLoading = false,
    String? sourceName,
    bool allowDataOwnershipTransfer = false,
    void Function()? onDispose,
  }) async {
    opens++;
    return document;
  }
}

void main() {
  var sequence = 0;
  late engine.PdfDocumentFactory originalFactory;
  late _Document document;
  late _Factory factory;
  setUp(() {
    originalFactory = engine.PdfDocumentFactory.instance;
    document = _Document('search-fixture-${sequence++}');
    factory = _Factory(document);
    engine.PdfDocumentFactory.instance = factory;
  });
  tearDown(() => engine.PdfDocumentFactory.instance = originalFactory);

  test('ready callback ignores detached or stale viewers', () {
    final controller = PdfReaderController(title: 'Ready guard');
    final detached = engine.PdfViewerController();
    controller.pdfViewerController = detached;
    expect(() => controller.onViewerReady(detached), returnsNormally);
    expect(
      () => controller.onViewerReady(engine.PdfViewerController()),
      returnsNormally,
    );
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'search keeps the viewer mounted and finds Chapter on $platform',
      (tester) async {
        const channel = MethodChannel('screen_protector');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (_) async => null,
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: PdfViewerScreen(
              title: 'Search fixture',
              fileUrl: 'https://pdf.invalid/${document.sourceName}',
              featureConfig: const PdfViewerFeatureConfig(
                enableTextSelection: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final controller = tester
            .widget<PdfReaderTopBar>(find.byType(PdfReaderTopBar))
            .controller;
        final viewerState = tester.state(find.byType(engine.PdfViewer));
        final initialOpens = factory.opens;
        expect(controller.pdfViewerController!.isReady, isTrue);
        await tester.tap(find.byTooltip('Search'));
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(engine.PdfViewer)), same(viewerState));

        await tester.enterText(find.byType(TextField), 'Chapter');
        await tester.pump(const Duration(milliseconds: 310));
        await tester.pumpAndSettle();
        expect(controller.searchResults.map((match) => match.pageNumber), [
          1,
          2,
        ]);
        expect(find.text('No results found'), findsNothing);
        expect(find.text('1 of 2'), findsOneWidget);
        expect(tester.state(find.byType(engine.PdfViewer)), same(viewerState));
        expect(controller.pdfViewerController!.isReady, isTrue);
        expect(factory.opens, initialOpens);
        expect(document.disposals, 0);

        await tester.tap(find.byTooltip('Next result'));
        await tester.pumpAndSettle();
        expect(find.text('2 of 2'), findsOneWidget);
        expect(controller.currentPage.value, 2);
        await tester.tap(find.byTooltip('Previous result'));
        await tester.pumpAndSettle();
        expect(find.text('1 of 2'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'unmatched');
        await tester.pump(const Duration(milliseconds: 310));
        await tester.pumpAndSettle();
        expect(find.text('No results found'), findsOneWidget);
        expect(tester.state(find.byType(engine.PdfViewer)), same(viewerState));
        await tester.enterText(find.byType(TextField), 'Chapter Two');
        await tester.pump(const Duration(milliseconds: 310));
        await tester.pumpAndSettle();
        expect(controller.searchResults.single.pageNumber, 2);
        controller.exitSearchMode();
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(engine.PdfViewer)), same(viewerState));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 600));
      },
      variant: TargetPlatformVariant.only(platform),
    );
  }

  for (final size in [const Size(686, 800), const Size(1280, 900)]) {
    testWidgets(
      'search reveals matches below controls at ${size.width}px and after resize',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        const channel = MethodChannel('screen_protector');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (_) async => null,
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: PdfViewerScreen(
              title: 'Search positioning',
              fileUrl: 'https://pdf.invalid/${document.sourceName}',
              featureConfig: const PdfViewerFeatureConfig(
                enableTextSelection: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final controller = tester
            .widget<PdfReaderTopBar>(find.byType(PdfReaderTopBar))
            .controller;
        unawaited(controller.applyFitMode(PdfFitMode.width));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Search'));
        await tester.pumpAndSettle();
        final viewerState = tester.state(find.byType(engine.PdfViewer));
        final viewer = controller.pdfViewerController!;

        void expectMatchVisible() {
          final match = controller
              .pdfTextSearcher!
              .matches[controller.currentSearchIndex.value];
          final rect = viewer.calcRectForRectInsidePage(
            pageNumber: match.pageNumber,
            rect: match.bounds,
          );
          final viewport = tester.getRect(find.byType(engine.PdfViewer));
          final controls = tester.getRect(find.byType(PdfSearchOverlay));
          final painted = MatrixUtils.transformRect(
            viewer.value,
            rect,
          ).shift(viewport.topLeft);
          expect(painted.top, greaterThanOrEqualTo(controls.bottom));
          expect(painted.bottom, lessThanOrEqualTo(viewport.bottom));
          expect(painted.left, greaterThanOrEqualTo(viewport.left));
          expect(painted.right, lessThanOrEqualTo(viewport.right));
          expect(
            tester.state(find.byType(engine.PdfViewer)),
            same(viewerState),
          );
        }

        await tester.enterText(find.byType(TextField), 'Chapter Two');
        await tester.pump(const Duration(milliseconds: 310));
        await tester.pumpAndSettle();
        expect(find.text('1 of 1'), findsOneWidget);
        expectMatchVisible();

        // Next must reveal even the sole match after a reader manually scrolls.
        unawaited(
          viewer.goToPage(
            pageNumber: 2,
            anchor: engine.PdfPageAnchor.bottom,
            duration: Duration.zero,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Next result'));
        await tester.pumpAndSettle();
        expectMatchVisible();

        // Real viewport changes must finish fitting before restoring the match.
        tester.view.physicalSize = Size(size.width - 100, size.height - 100);
        await tester.pumpAndSettle();
        expectMatchVisible();

        await tester.enterText(find.byType(TextField), 'Chapter');
        await tester.pump(const Duration(milliseconds: 310));
        await tester.pumpAndSettle();
        expect(find.text('1 of 2'), findsOneWidget);
        expectMatchVisible();
        await tester.tap(find.byTooltip('Next result'));
        await tester.pumpAndSettle();
        expect(find.text('2 of 2'), findsOneWidget);
        expectMatchVisible();
        await tester.tap(find.byTooltip('Previous result'));
        await tester.pumpAndSettle();
        expect(find.text('1 of 2'), findsOneWidget);
        expectMatchVisible();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 600));
      },
    );
  }

  testWidgets(
    'in-memory viewer retries the latest query after attachment and shows progress',
    (tester) async {
      final controller = PdfReaderController(
        title: 'Memory search',
        fileUrl: 'https://pdf.invalid/memory',
      );
      await controller.loadPdf();
      controller.enterSearchMode();
      await controller.performSearch('old query');
      await controller.performSearch('Chapter Two');
      expect(controller.isSearching.value, isTrue);
      document.textGate = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PdfSearchOverlay(
                  controller: controller,
                  onClose: controller.exitSearchMode,
                ),
                Expanded(
                  child: engine.PdfViewer(
                    engine.PdfDocumentRefDirect(document, autoDispose: false),
                    controller: controller.pdfViewerController,
                    params: engine.PdfViewerParams(
                      enableTextSelection: false,
                      onViewerReady: (_, viewer) =>
                          controller.onViewerReady(viewer),
                      onViewSizeChanged: (_, __, viewer) =>
                          controller.onViewerViewSizeChanged(viewer),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Searching…'), findsOneWidget);
      expect(find.text('No results found'), findsNothing);
      document.textGate!.complete();
      await tester.pumpAndSettle();
      expect(controller.searchResults.single.pageNumber, 2);
      expect(controller.isSearching.value, isFalse);
      expect(find.text('1 of 1'), findsOneWidget);
      final viewer = controller.pdfViewerController!;
      final match = controller.pdfTextSearcher!.matches.single;
      final matchRect = viewer.calcRectForRectInsidePage(
        pageNumber: match.pageNumber,
        rect: match.bounds,
      );
      expect(viewer.visibleRect.containsRect(matchRect), isTrue);
      expect(
        tester.getRect(find.byType(engine.PdfViewer)).top,
        greaterThanOrEqualTo(
          tester.getRect(find.byType(PdfSearchOverlay)).bottom,
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    },
  );
}
