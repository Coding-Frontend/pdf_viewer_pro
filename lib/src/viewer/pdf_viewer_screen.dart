import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:screen_protector/screen_protector.dart';

import 'pdf_reader_controller.dart';
import 'pdf_navigation_bars.dart';
import 'pdf_settings_sheet.dart';
import 'pdf_bookmarks_sheet.dart';
import 'pdf_thumbnails_drawer.dart';
import 'pdf_search_overlay.dart';
import '../annotations/annotation_toolbar.dart';
import '../annotations/annotation_canvas.dart';
import '../annotations/annotation_models.dart';
import '../service_config.dart';
import '../viewer_theme_config.dart';
import '../feature_config.dart';

/// Main PDF viewer screen using pdfrx (PDFium FFI)
class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String? fileUrl;
  final String title;
  final bool enableDrm;
  final VoidCallback? onClose;
  final int? bookId;
  final bool isSamplePreview;
  final PdfViewerServiceConfig serviceConfig;
  final PdfViewerThemeConfig themeConfig;
  final PdfViewerFeatureConfig featureConfig;

  /// Optional reactive dark mode observable from the host app.
  final RxBool? externalDarkMode;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    this.fileUrl,
    required this.title,
    this.enableDrm = false,
    this.onClose,
    this.bookId,
    this.isSamplePreview = false,
    this.serviceConfig = const PdfViewerServiceConfig(),
    this.themeConfig = const PdfViewerThemeConfig(),
    this.featureConfig = const PdfViewerFeatureConfig(),
    this.externalDarkMode,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with WidgetsBindingObserver {
  late PdfReaderController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
    _setupDrm();
  }

  void _initController() {
    _controller = Get.put(
      PdfReaderController(
        filePath: widget.filePath,
        fileUrl: widget.fileUrl,
        title: widget.title,
        bookId: widget.bookId,
        isSamplePreview: widget.isSamplePreview,
        serviceConfig: widget.serviceConfig,
        themeConfig: widget.themeConfig,
        featureConfig: widget.featureConfig,
        externalDarkMode: widget.externalDarkMode,
      ),
    );
  }

  Future<void> _setupDrm() async {
    if (widget.enableDrm) {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
    }
  }

  Future<void> _teardownDrm() async {
    if (widget.enableDrm) {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _teardownDrm();
    Get.delete<PdfReaderController>();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.saveProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = _controller.isDarkMode.value;
      final bgColor =
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
      final statusBarColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final showControls = _controller.showControls.value;
      final isFullscreen = _controller.isFullscreen.value;
      final isSearchMode = _controller.isSearchMode.value;

      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: statusBarColor,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: statusBarColor,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      );

      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: bgColor,
        drawer: const PdfThumbnailsDrawer(),
        body: _controller.isLoading.value
            ? _buildLoadingState(isDark)
            : _controller.hasError.value
                ? _buildErrorState(isDark)
                : isFullscreen
                    // Fullscreen mode - PDF fills entire screen
                    ? Stack(
                        children: [
                          GestureDetector(
                            onTap: _controller.toggleControls,
                            onDoubleTap: () => _controller.toggleFullscreen(),
                            child: _buildPdfViewer(isDark),
                          ),
                          // Exit button in fullscreen
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            right: 8,
                            child: _buildFullscreenExitButton(isDark),
                          ),
                        ],
                      )
                    // Normal mode - PDF sits between bars
                    : Stack(
                        children: [
                          Column(
                            children: [
                              // Top bar
                              if (showControls && !isSearchMode)
                                PdfReaderTopBar(
                                  onBack: () {
                                    _controller.saveProgress();
                                    widget.onClose?.call();
                                    Get.back();
                                  },
                                  onOpenThumbnails: () =>
                                      _scaffoldKey.currentState?.openDrawer(),
                                  onOpenBookmarks: () => _showBookmarksSheet(),
                                  onOpenSettings: () => _showSettingsSheet(),
                                  onSearch: () => _controller.enterSearchMode(),
                                ),
                              // Annotation toolbar (below top bar when active)
                              if (showControls && !isSearchMode)
                                Obx(() => AnnotationToolbar(
                                      controller:
                                          _controller.annotationController,
                                      isDarkMode: _controller.isDarkMode.value,
                                      canUndo: _controller.canUndo,
                                      canRedo: _controller.canRedo,
                                      onUndo: () =>
                                          _controller.undoAnnotation(),
                                      onRedo: () =>
                                          _controller.redoAnnotation(),
                                      onClear: () =>
                                          _controller.clearPageAnnotations(
                                              _controller.currentPage.value),
                                    )),
                              // PDF Viewer (expanded to fill remaining space)
                              Expanded(
                                child: Stack(
                                  children: [
                                    // PDF viewer - use Row layout when search mode is active
                                    if (isSearchMode && _controller.searchResults.isNotEmpty)
                                      Row(
                                        children: [
                                          // PDF takes remaining space (minus minimap width)
                                          Expanded(
                                            child: GestureDetector(
                                              child: _buildPdfViewer(isDark),
                                            ),
                                          ),
                                          // Minimap on the right
                                          SizedBox(
                                            width: 48,
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 120, bottom: 8, right: 8, left: 4),
                                              child: _buildSearchMinimap(isDark),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      GestureDetector(
                                        onTap: isSearchMode
                                            ? null
                                            : _controller.toggleControls,
                                        onDoubleTap: isSearchMode
                                            ? null
                                            : () => _controller.toggleFullscreen(),
                                        child: _buildPdfViewer(isDark),
                                      ),
                                    // Search mode overlay - only shows top bar
                                    if (isSearchMode)
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: PdfSearchOverlay(
                                          onClose: () =>
                                              _controller.exitSearchMode(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Bottom bar
                              if (showControls && !isSearchMode)
                                PdfReaderBottomBar(
                                  onPrevPage: () =>
                                      _controller.goToPreviousPage(),
                                  onNextPage: () => _controller.goToNextPage(),
                                  onToggleScrollDirection: () =>
                                      _controller.toggleScrollDirection(),
                                  onGoToPage: () => _showGoToPageDialog(),
                                ),
                            ],
                          ),
                          // Floating edit/done (annotations) button
                          if (!isSearchMode)
                            Positioned(
                              right: 16,
                              bottom: MediaQuery.of(context).padding.bottom +
                                  (showControls ? 130 : 16),
                              child: FloatingActionButton.extended(
                                heroTag: 'edit_fab',
                                onPressed: () =>
                                    _controller.toggleAnnotationMode(),
                                backgroundColor:
                                    _controller.isAnnotationModeActive
                                        ? Theme.of(context).primaryColor
                                        : (isDark
                                            ? const Color(0xFF2a2a2a)
                                            : Colors.white),
                                elevation: 4,
                                icon: Icon(
                                  _controller.isAnnotationModeActive
                                      ? Icons.check
                                      : Icons.edit,
                                  color: _controller.isAnnotationModeActive
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                                label: Text(
                                  _controller.isAnnotationModeActive
                                      ? 'Done'
                                      : 'Edit',
                                  style: TextStyle(
                                    color: _controller.isAnnotationModeActive
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white
                                            : Colors.black87),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
      );
    });
  }

  /// Build search results minimap for quick navigation
  Widget _buildSearchMinimap(bool isDark) {
    return Obx(() {
      final totalPages = _controller.totalPages.value;
      final currentPage = _controller.currentPage.value;
      final searchResults = _controller.searchResults;
      final currentSearchIndex = _controller.currentSearchIndex.value;
      final primaryColor = Theme.of(context).primaryColor;

      if (totalPages == 0) return const SizedBox.shrink();

      // Group search results by page
      final resultsByPage = <int, int>{};
      for (final result in searchResults) {
        resultsByPage[result.pageNumber] =
            (resultsByPage[result.pageNumber] ?? 0) + 1;
      }

      return GestureDetector(
        onVerticalDragUpdate: (details) {
          // Handle drag to scroll through pages
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPosition = box.globalToLocal(details.globalPosition);
            final height = box.size.height;
            final page = ((localPosition.dy / height) * totalPages)
                .clamp(1, totalPages)
                .round();
            _controller.goToPage(page);
          }
        },
        onTapDown: (details) {
          // Handle tap to go to specific page
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final localPosition = box.globalToLocal(details.globalPosition);
            final height = box.size.height;
            final page = ((localPosition.dy / height) * totalPages)
                .clamp(1, totalPages)
                .round();
            
            // Check if tapped on a search result page
            if (resultsByPage.containsKey(page)) {
              final resultIndex =
                  searchResults.indexWhere((r) => r.pageNumber == page);
              if (resultIndex != -1) {
                _controller.currentSearchIndex.value = resultIndex;
              }
            }
            _controller.goToPage(page);
          }
        },
        child: Container(
          width: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final pageHeight = height / totalPages;

              // Build result markers
              final markers = <Widget>[];

              // Page position marker (full width blue bar)
              final currentPagePosition = (currentPage - 1) * pageHeight;
              markers.add(
                Positioned(
                  top: currentPagePosition,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: pageHeight.clamp(3.0, 12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );

              // Search result markers
              for (final entry in resultsByPage.entries) {
                final page = entry.key;
                final top = (page - 1) * pageHeight;

                // Check if this page contains the current search result
                final isCurrentResultPage = searchResults.isNotEmpty &&
                    searchResults[currentSearchIndex].pageNumber == page;

                markers.add(
                  Positioned(
                    top: top,
                    left: 4,
                    right: 4,
                    child: Container(
                      height: pageHeight.clamp(4.0, 10.0),
                      decoration: BoxDecoration(
                        color: isCurrentResultPage
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                        border: isCurrentResultPage
                            ? Border.all(color: Colors.white, width: 1)
                            : null,
                      ),
                    ),
                  ),
                );
              }

              return Stack(children: markers);
            },
          ),
        ),
      );
    });
  }

  Widget _buildLoadingState(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    return Obx(() {
      final progress = _controller.loadingProgress.value;
      final isDownloading = progress > 0 && progress < 1;
      final downloadedBytes = _controller.downloadedBytes.value;
      final totalBytes = _controller.totalBytes.value;

      // Format bytes to human readable
      String formatBytes(int bytes) {
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDownloading) ...[
              // Download progress indicator
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation(primaryColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.download_rounded,
                          size: 28,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Downloading PDF...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
              if (totalBytes > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${formatBytes(downloadedBytes)} / ${formatBytes(totalBytes)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ] else ...[
              CircularProgressIndicator(
                color: primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading PDF...',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildErrorState(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load PDF',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _controller.loadPdf(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer(bool isDark) {
    if (_controller.pdfDocument == null) {
      return const SizedBox.shrink();
    }

    final bgColor = isDark ? const Color(0xFF1a1a1a) : const Color(0xFFE0E0E0);
    final scrollDirection = _controller.scrollDirection.value;
    final isHorizontal = scrollDirection == Axis.horizontal;

    // Use local file path from controller (after download if needed)
    final effectiveFilePath =
        _controller.localFilePath.value ?? widget.filePath;
    debugPrint(
        'PdfViewer using path: $effectiveFilePath, scrollDirection: $scrollDirection');

    return Container(
      color: bgColor,
      child: PdfViewer.file(
        effectiveFilePath,
        // Use key to force rebuild when scroll direction changes
        key: ValueKey('pdf_viewer_${scrollDirection.name}'),
        controller: _controller.pdfViewerController,
        params: PdfViewerParams(
          backgroundColor: bgColor,
          enableTextSelection: true,
          // In horizontal mode, use top anchor for page alignment; in vertical use all
          pageAnchor: isHorizontal ? PdfPageAnchor.top : PdfPageAnchor.all,
          // Use layoutPages for horizontal/vertical scrolling
          layoutPages: isHorizontal ? _horizontalLayout : null,
          // Custom text selection toolbar with highlight/note options
          selectableRegionInjector: (context, child) {
            return SelectionArea(
              contextMenuBuilder: (context, selectableRegionState) {
                return _buildTextSelectionToolbar(
                  context,
                  selectableRegionState,
                );
              },
              child: child,
            );
          },
          onPageChanged: (pageNumber) {
            if (pageNumber != null) {
              _controller.onPageChanged(pageNumber);
            }
          },
          // Add annotation canvas overlay and bookmark icon on each page
          pageOverlaysBuilder: (context, pageRect, page) {
            final pageNum = page.pageNumber;

            return [
              // Bookmark icon on each page corner - wrapped in Obx for reactivity
              Positioned(
                top: 8,
                right: 8,
                child: Obx(() {
                  final isBookmarked =
                      _controller.bookmarkedPages.contains(pageNum);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _controller.toggleBookmarkForPage(pageNum),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isBookmarked
                              ? Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // Annotation canvas - wrapped in Obx for reactivity
              Obx(() {
                // Access pageAnnotations.value to ensure GetX tracks changes to the map
                final allAnnotations = _controller.pageAnnotations;
                final annotations = allAnnotations[pageNum] ??
                    PageAnnotations(pageNumber: pageNum);
                final isAnnotationMode =
                    _controller.annotationController.isAnnotationMode.value;
                final activeTool =
                    _controller.annotationController.selectedTool.value;

                if (!isAnnotationMode &&
                    annotations.strokes.isEmpty &&
                    annotations.notes.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Scale annotations to current pageRect size
                final scaledStrokes = annotations.getScaledStrokes(
                    pageRect.width, pageRect.height);
                final scaledNotes =
                    annotations.getScaledNotes(pageRect.width, pageRect.height);

                return Positioned.fill(
                  child: AnnotationCanvas(
                    canvasSize: Size(pageRect.width, pageRect.height),
                    activeTool: isAnnotationMode ? activeTool : null,
                    penColor: _controller.annotationController.currentColor,
                    highlightColor: _controller
                        .annotationController.currentColor
                        .withValues(alpha: 0.4),
                    strokeWidth: _controller
                        .annotationController.selectedStrokeWidth.value,
                    strokes: scaledStrokes,
                    notes: scaledNotes,
                    enabled: isAnnotationMode,
                    onStrokeCompleted: (stroke) => _controller.addStroke(
                      pageNum,
                      stroke,
                      refWidth: pageRect.width,
                      refHeight: pageRect.height,
                    ),
                    onNoteRequested: (offset) => _showNoteDialog(
                        pageNum, offset,
                        refWidth: pageRect.width, refHeight: pageRect.height),
                    onEraseStroke: (strokeId) =>
                        _controller.removeStroke(pageNum, strokeId),
                    onNoteTapped: (note) => _showNoteDialog(
                        pageNum, Offset(note.x, note.y),
                        existingNote: note,
                        refWidth: pageRect.width,
                        refHeight: pageRect.height),
                  ),
                );
              }),
            ];
          },
          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
            return Center(
              child: CircularProgressIndicator(
                value: totalBytes != null && totalBytes > 0
                    ? bytesDownloaded / totalBytes
                    : null,
                color: Theme.of(context).primaryColor,
              ),
            );
          },
          errorBannerBuilder: (context, error, stackTrace, documentRef) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading page',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          },
          pagePaintCallbacks: [
            if (isDark)
              (canvas, pageRect, page) {
                canvas.drawRect(
                  pageRect,
                  Paint()
                    ..color = Colors.black.withValues(alpha: 0.1)
                    ..blendMode = BlendMode.darken,
                );
              },
          ],
        ),
      ),
    );
  }

  /// Horizontal layout for pages (swipe left/right)
  PdfPageLayout _horizontalLayout(List<PdfPage> pages, PdfViewerParams params) {
    final margin = params.margin;
    double maxHeight = 0;
    for (final page in pages) {
      if (page.height > maxHeight) {
        maxHeight = page.height;
      }
    }
    final height = maxHeight + margin * 2;

    final pageLayouts = <Rect>[];
    double x = margin;
    for (final page in pages) {
      pageLayouts.add(
        Rect.fromLTWH(
          x,
          (height - page.height) / 2, // center vertically
          page.width,
          page.height,
        ),
      );
      x += page.width + margin;
    }
    return PdfPageLayout(
        pageLayouts: pageLayouts, documentSize: Size(x, height));
  }

  Widget _buildFullscreenExitButton(bool isDark) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _controller.toggleFullscreen(),
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.fullscreen_exit,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    Get.bottomSheet(
      const PdfSettingsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showBookmarksSheet() {
    Get.bottomSheet(
      const PdfBookmarksSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildTextSelectionToolbar(
    BuildContext context,
    SelectableRegionState selectableRegionState,
  ) {
    final isDark = _controller.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    return AdaptiveTextSelectionToolbar(
      anchors: selectableRegionState.contextMenuAnchors,
      children: [
        Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Copy button
                InkWell(
                  onTap: () {
                    selectableRegionState
                        .copySelection(SelectionChangedCause.toolbar);
                    selectableRegionState.hideToolbar();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, color: primaryColor, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(color: textColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                // Note button
                InkWell(
                  onTap: () {
                    selectableRegionState.hideToolbar();
                    _showAddNoteForTextDialog();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_add, color: primaryColor, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Note',
                          style: TextStyle(color: textColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddNoteForTextDialog() {
    final isDark = _controller.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final noteController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Note', style: TextStyle(color: textColor)),
        content: TextField(
          controller: noteController,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Enter your note for the selected text...',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.isNotEmpty) {
                _controller.addTextNote(
                  _controller.currentPage.value,
                  'Selected text',
                  noteController.text,
                );
                Get.back();
                Get.snackbar(
                  'Note Added',
                  'Your note has been saved',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor:
                      isDark ? const Color(0xFF2a2a2a) : Colors.white,
                  colorText: textColor,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGoToPageDialog() {
    final isDark = _controller.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Go to Page', style: TextStyle(color: textColor)),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Enter page number (1-${_controller.totalPages.value})',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(textController.text);
              if (page != null &&
                  page >= 1 &&
                  page <= _controller.totalPages.value) {
                _controller.goToPage(page);
                Get.back();
              }
            },
            child: Text('Go',
                style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(int pageNum, Offset offset,
      {TextNote? existingNote, double? refWidth, double? refHeight}) {
    final isDark = _controller.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textController =
        TextEditingController(text: existingNote?.text ?? '');

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existingNote != null ? 'Edit Note' : 'Add Note',
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 4,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Enter your note...',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          if (existingNote != null)
            TextButton(
              onPressed: () {
                _controller.removeNote(pageNum, existingNote.id);
                Get.back();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red[400])),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                if (existingNote != null) {
                  _controller.updateNote(
                      pageNum, existingNote.copyWith(text: text));
                } else {
                  final note = TextNote(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    x: offset.dx,
                    y: offset.dy,
                    text: text,
                    createdAt: DateTime.now(),
                  );
                  _controller.addNote(pageNum, note,
                      refWidth: refWidth, refHeight: refHeight);
                }
                Get.back();
              }
            },
            child: Text('Save',
                style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }
}

/// Alternative PDF viewer using file path directly
class PdfViewerFromPath extends StatefulWidget {
  final String filePath;
  final String title;
  final bool enableDrm;
  final VoidCallback? onClose;

  const PdfViewerFromPath({
    super.key,
    required this.filePath,
    required this.title,
    this.enableDrm = false,
    this.onClose,
  });

  @override
  State<PdfViewerFromPath> createState() => _PdfViewerFromPathState();
}

class _PdfViewerFromPathState extends State<PdfViewerFromPath>
    with WidgetsBindingObserver {
  late PdfReaderController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
    _setupDrm();
  }

  void _initController() {
    _controller = Get.put(
      PdfReaderController(
        filePath: widget.filePath,
        title: widget.title,
      ),
    );
  }

  Future<void> _setupDrm() async {
    if (widget.enableDrm) {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
    }
  }

  Future<void> _teardownDrm() async {
    if (widget.enableDrm) {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _teardownDrm();
    Get.delete<PdfReaderController>();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.saveProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = _controller.isDarkMode.value;
      final bgColor =
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
      final showControls = _controller.showControls.value;
      final isFullscreen = _controller.isFullscreen.value;
      final isSearchMode = _controller.isSearchMode.value;

      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: bgColor,
        drawer: const PdfThumbnailsDrawer(),
        body: _controller.isLoading.value
            ? _buildLoadingState(isDark)
            : _controller.hasError.value
                ? _buildErrorState(isDark)
                : Stack(
                    children: [
                      GestureDetector(
                        onTap: isSearchMode ? null : _controller.toggleControls,
                        onDoubleTap: isSearchMode
                            ? null
                            : () => _controller.toggleFullscreen(),
                        child: _buildDirectPdfViewer(isDark),
                      ),
                      // Search mode overlay (Google Drive style) - only shows top bar
                      if (isSearchMode)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: PdfSearchOverlay(
                            onClose: () => _controller.exitSearchMode(),
                          ),
                        ),
                      if (showControls && !isFullscreen && !isSearchMode) ...[
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: PdfReaderTopBar(
                            onBack: () {
                              _controller.saveProgress();
                              widget.onClose?.call();
                              Get.back();
                            },
                            onOpenThumbnails: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            onOpenBookmarks: () => _showBookmarksSheet(),
                            onOpenSettings: () => _showSettingsSheet(),
                            onSearch: () => _controller.enterSearchMode(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: PdfReaderBottomBar(
                            onPrevPage: () => _controller.goToPreviousPage(),
                            onNextPage: () => _controller.goToNextPage(),
                            onToggleScrollDirection: () =>
                                _controller.toggleScrollDirection(),
                            onGoToPage: () => _showGoToPageDialog(),
                          ),
                        ),
                      ],
                      // Floating edit/done (annotations) button
                      if (!isSearchMode)
                        Positioned(
                          right: 16,
                          bottom: MediaQuery.of(context).padding.bottom +
                              (showControls && !isFullscreen ? 130 : 16),
                          child: FloatingActionButton.extended(
                            heroTag: 'edit_fab_direct',
                            onPressed: () => _controller.toggleAnnotationMode(),
                            backgroundColor: _controller.isAnnotationModeActive
                                ? Theme.of(context).primaryColor
                                : (isDark
                                    ? const Color(0xFF2a2a2a)
                                    : Colors.white),
                            elevation: 4,
                            icon: Icon(
                              _controller.isAnnotationModeActive
                                  ? Icons.check
                                  : Icons.edit,
                              color: _controller.isAnnotationModeActive
                                  ? Colors.white
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                            label: Text(
                              _controller.isAnnotationModeActive
                                  ? 'Done'
                                  : 'Edit',
                              style: TextStyle(
                                color: _controller.isAnnotationModeActive
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black87),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      // Always show exit button in fullscreen mode (regardless of controls visibility)
                      if (isFullscreen && !isSearchMode)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          right: 8,
                          child: _buildFullscreenExitButton(),
                        ),
                    ],
                  ),
      );
    });
  }

  Widget _buildLoadingState(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    return Obx(() {
      final progress = _controller.loadingProgress.value;
      final isDownloading = progress > 0 && progress < 1;
      final downloadedBytes = _controller.downloadedBytes.value;
      final totalBytes = _controller.totalBytes.value;

      // Format bytes to human readable
      String formatBytes(int bytes) {
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isDownloading) ...[
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.black12,
                        valueColor: AlwaysStoppedAnimation(primaryColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded,
                            size: 28, color: primaryColor),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Downloading PDF...',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.8)),
              ),
              if (totalBytes > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${formatBytes(downloadedBytes)} / ${formatBytes(totalBytes)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ] else ...[
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading PDF...',
                style: TextStyle(
                    fontSize: 16, color: textColor.withValues(alpha: 0.7)),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildErrorState(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load PDF',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: textColor.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                    onPressed: () => Get.back(), child: const Text('Go Back')),
                const SizedBox(width: 16),
                ElevatedButton(
                    onPressed: () => _controller.loadPdf(),
                    child: const Text('Retry')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectPdfViewer(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1a1a1a) : const Color(0xFFE0E0E0);
    final scrollDirection = _controller.scrollDirection.value;
    final isHorizontal = scrollDirection == Axis.horizontal;

    // Use local file path from controller (after download if needed)
    final effectiveFilePath =
        _controller.localFilePath.value ?? widget.filePath;

    return Container(
      color: bgColor,
      child: PdfViewer.file(
        effectiveFilePath,
        // Use key to force rebuild when scroll direction changes
        key: ValueKey('pdf_viewer_direct_${scrollDirection.name}'),
        controller: _controller.pdfViewerController,
        params: PdfViewerParams(
          backgroundColor: bgColor,
          enableTextSelection: true,
          // In horizontal mode, use top anchor for page alignment; in vertical use all
          pageAnchor: isHorizontal ? PdfPageAnchor.top : PdfPageAnchor.all,
          layoutPages: isHorizontal ? _horizontalLayout : null,
          // Custom text selection toolbar with highlight/note options
          selectableRegionInjector: (context, child) {
            return SelectionArea(
              contextMenuBuilder: (context, selectableRegionState) {
                return _buildTextSelectionToolbar(
                  context,
                  selectableRegionState,
                );
              },
              child: child,
            );
          },
          onPageChanged: (pageNumber) {
            if (pageNumber != null) {
              _controller.onPageChanged(pageNumber);
            }
          },
          // Add annotation canvas overlay and bookmark icon on each page
          pageOverlaysBuilder: (context, pageRect, page) {
            final pageNum = page.pageNumber;

            return [
              // Bookmark icon on each page corner - wrapped in Obx for reactivity
              Positioned(
                top: 8,
                right: 8,
                child: Obx(() {
                  final isBookmarked =
                      _controller.bookmarkedPages.contains(pageNum);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _controller.toggleBookmarkForPage(pageNum),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isBookmarked
                              ? Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // Annotation canvas - wrapped in Obx for reactivity
              Obx(() {
                // Access pageAnnotations.value to ensure GetX tracks changes to the map
                final allAnnotations = _controller.pageAnnotations;
                final annotations = allAnnotations[pageNum] ??
                    PageAnnotations(pageNumber: pageNum);
                final isAnnotationMode =
                    _controller.annotationController.isAnnotationMode.value;
                final activeTool =
                    _controller.annotationController.selectedTool.value;

                if (!isAnnotationMode &&
                    annotations.strokes.isEmpty &&
                    annotations.notes.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Scale annotations to current pageRect size
                final scaledStrokes = annotations.getScaledStrokes(
                    pageRect.width, pageRect.height);
                final scaledNotes =
                    annotations.getScaledNotes(pageRect.width, pageRect.height);

                return Positioned.fill(
                  child: AnnotationCanvas(
                    canvasSize: Size(pageRect.width, pageRect.height),
                    activeTool: isAnnotationMode ? activeTool : null,
                    penColor: _controller.annotationController.currentColor,
                    highlightColor: _controller
                        .annotationController.currentColor
                        .withValues(alpha: 0.4),
                    strokeWidth: _controller
                        .annotationController.selectedStrokeWidth.value,
                    strokes: scaledStrokes,
                    notes: scaledNotes,
                    enabled: isAnnotationMode,
                    onStrokeCompleted: (stroke) => _controller.addStroke(
                      pageNum,
                      stroke,
                      refWidth: pageRect.width,
                      refHeight: pageRect.height,
                    ),
                    onNoteRequested: (offset) => _showNoteDialogForPath(
                        pageNum, offset,
                        refWidth: pageRect.width, refHeight: pageRect.height),
                    onEraseStroke: (strokeId) =>
                        _controller.removeStroke(pageNum, strokeId),
                    onNoteTapped: (note) => _showNoteDialogForPath(
                        pageNum, Offset(note.x, note.y),
                        existingNote: note,
                        refWidth: pageRect.width,
                        refHeight: pageRect.height),
                  ),
                );
              }),
            ];
          },
        ),
      ),
    );
  }

  void _showNoteDialogForPath(int pageNum, Offset offset,
      {TextNote? existingNote, double? refWidth, double? refHeight}) {
    final isDark = _controller.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textController =
        TextEditingController(text: existingNote?.text ?? '');

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          existingNote != null ? 'Edit Note' : 'Add Note',
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLines: 4,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Enter your note...',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          if (existingNote != null)
            TextButton(
              onPressed: () {
                _controller.removeNote(pageNum, existingNote.id);
                Get.back();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red[400])),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                if (existingNote != null) {
                  _controller.updateNote(
                      pageNum, existingNote.copyWith(text: text));
                } else {
                  final note = TextNote(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    x: offset.dx,
                    y: offset.dy,
                    text: text,
                    createdAt: DateTime.now(),
                  );
                  _controller.addNote(pageNum, note,
                      refWidth: refWidth, refHeight: refHeight);
                }
                Get.back();
              }
            },
            child: Text('Save',
                style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  /// Horizontal layout for pages (swipe left/right)
  PdfPageLayout _horizontalLayout(List<PdfPage> pages, PdfViewerParams params) {
    final margin = params.margin;
    double maxHeight = 0;
    for (final page in pages) {
      if (page.height > maxHeight) {
        maxHeight = page.height;
      }
    }
    final height = maxHeight + margin * 2;

    final pageLayouts = <Rect>[];
    double x = margin;
    for (final page in pages) {
      pageLayouts.add(
        Rect.fromLTWH(
          x,
          (height - page.height) / 2, // center vertically
          page.width,
          page.height,
        ),
      );
      x += page.width + margin;
    }
    return PdfPageLayout(
        pageLayouts: pageLayouts, documentSize: Size(x, height));
  }

  Widget _buildFullscreenExitButton() {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _controller.toggleFullscreen(),
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.fullscreen_exit, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    Get.bottomSheet(const PdfSettingsSheet(),
        isScrollControlled: true, backgroundColor: Colors.transparent);
  }

  void _showBookmarksSheet() {
    Get.bottomSheet(const PdfBookmarksSheet(),
        isScrollControlled: true, backgroundColor: Colors.transparent);
  }

  Widget _buildTextSelectionToolbar(
    BuildContext context,
    SelectableRegionState selectableRegionState,
  ) {
    final isDark = _controller.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    return AdaptiveTextSelectionToolbar(
      anchors: selectableRegionState.contextMenuAnchors,
      children: [
        Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Copy button
                InkWell(
                  onTap: () {
                    selectableRegionState
                        .copySelection(SelectionChangedCause.toolbar);
                    selectableRegionState.hideToolbar();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy, color: primaryColor, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(color: textColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                // Note button
                InkWell(
                  onTap: () {
                    selectableRegionState.hideToolbar();
                    _showAddNoteForTextDialog();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_add, color: primaryColor, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Note',
                          style: TextStyle(color: textColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddNoteForTextDialog() {
    final isDark = _controller.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final noteController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Note', style: TextStyle(color: textColor)),
        content: TextField(
          controller: noteController,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Enter your note for the selected text...',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.isNotEmpty) {
                _controller.addTextNote(
                  _controller.currentPage.value,
                  'Selected text',
                  noteController.text,
                );
                Get.back();
                Get.snackbar(
                  'Note Added',
                  'Your note has been saved',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor:
                      isDark ? const Color(0xFF2a2a2a) : Colors.white,
                  colorText: textColor,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGoToPageDialog() {
    final isDark = _controller.isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Go to Page', style: TextStyle(color: textColor)),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Enter page number (1-${_controller.totalPages.value})',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(textController.text);
              if (page != null &&
                  page >= 1 &&
                  page <= _controller.totalPages.value) {
                _controller.goToPage(page);
                Get.back();
              }
            },
            child: Text('Go',
                style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }
}
