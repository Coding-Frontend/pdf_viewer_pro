import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/reactive.dart';
import '../core/storage.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../service_config.dart';
import '../viewer_theme_config.dart';
import '../feature_config.dart';
import '../annotations/annotation_models.dart';
import '../annotations/annotation_toolbar.dart';

enum PdfFitMode { custom, page, width, height }

/// Controller for PDF Reader using pdfrx (PDFium FFI)
class PdfReaderController extends PluginController {
  final String? filePath;
  final String? fileUrl;
  final String title;
  final int? bookId;
  final int initialPage;
  final bool isSamplePreview;
  final PdfViewerServiceConfig serviceConfig;
  final PdfViewerThemeConfig themeConfig;
  final PdfViewerFeatureConfig featureConfig;

  /// Optional reactive dark mode observable from the host app.
  /// When provided, the controller listens for changes and updates its own
  /// [isDarkMode] accordingly. Pass `yourSettingsController.themeMode` or similar.
  final RxBool? externalDarkMode;

  PdfReaderController({
    this.filePath,
    this.fileUrl,
    required this.title,
    this.bookId,
    this.initialPage = 1,
    this.isSamplePreview = false,
    this.serviceConfig = const PdfViewerServiceConfig(),
    this.themeConfig = const PdfViewerThemeConfig(),
    this.featureConfig = const PdfViewerFeatureConfig(),
    this.externalDarkMode,
  });

  PluginStorage _storage = PluginStorage.memory();

  // PDF Document
  PdfDocument? pdfDocument;
  PdfViewerController? pdfViewerController;
  PdfTextSearcher? pdfTextSearcher;
  String? _resolvedFilePath;

  /// The local file path of the PDF (after download if needed)
  final localFilePath = Rx<String?>(null);

  // Loading State
  final isLoading = true.obs;
  final hasError = false.obs;
  final error = ''.obs;
  final errorMessage = ''.obs;
  final loadingProgress = 0.0.obs;
  final downloadedBytes = 0.obs;
  final totalBytes = 0.obs;

  // Table of Contents
  final tableOfContents = <TocItem>[].obs;

  // UI State
  final showControls = true.obs;
  final isFullscreen = false.obs;
  final keepScreenOn = false.obs;
  final isSearchMode = false.obs;
  final searchQuery = ''.obs;
  final searchResults = <PdfTextMatch>[].obs;
  final currentSearchIndex = 0.obs;

  // Reading State
  final currentPage = 1.obs;
  final totalPages = 0.obs;
  final progress = 0.0.obs;

  // Settings
  final isDarkMode = false.obs;
  final scrollDirection = Rx<Axis>(Axis.vertical);
  final zoomLevel = 1.0.obs;
  final fitMode = Rx<PdfFitMode>(PdfFitMode.page);
  final rotationQuarterTurns = 0.obs;

  // Auto-scroll
  final isAutoScrolling = false.obs;
  final autoScrollIntervalSeconds = 30.obs;
  final autoScrollProgress = 0.0.obs;
  Timer? _autoScrollTimer;
  Timer? _autoScrollProgressTimer;

  // Bookmarks
  final bookmarkedPages = <int>[].obs;

  // Annotations
  final annotationController = AnnotationToolbarController();
  final pageAnnotations = <int, PageAnnotations>{}.obs;
  final undoStack = <Map<String, dynamic>>[].obs;
  final redoStack = <Map<String, dynamic>>[].obs;

  // Session tracking
  DateTime? _sessionStartTime;
  Timer? _autoSaveTimer;
  Timer? _controlsHideTimer;
  VoidCallback? _themeListener;
  VoidCallback? _pdfTextSearchListener;
  VoidCallback? _pdfViewerTransformListener;

  @override
  void onInit() {
    super.onInit();
    _storage = serviceConfig.storage ?? PluginStorage.memory();
    _enableScreenProtector();
    _loadPreferences();
    _initializeReader();

    // Listen for app theme changes if external dark mode is provided
    if (externalDarkMode != null) {
      _themeListener = ever(externalDarkMode!, (value) {
        isDarkMode.value = value;
      });
    }
  }

  @override
  void onClose() {
    _endReadingSession();
    _autoSaveTimer?.cancel();
    _controlsHideTimer?.cancel();
    _autoScrollTimer?.cancel();
    _autoScrollProgressTimer?.cancel();
    _themeListener?.call();
    _pdfTextSearchListener?.call();
    final viewerController = pdfViewerController;
    final transformListener = _pdfViewerTransformListener;
    if (viewerController != null && transformListener != null) {
      viewerController.removeListener(transformListener);
    }
    pdfTextSearcher?.dispose();
    pdfDocument?.dispose();
    _disableScreenProtector();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }

  int get _bookIdForStorage => bookId ?? 0;

  /// Show a message using the configured callback, or silently ignore.
  void _showMessage(String message, ViewerMessageType type) {
    serviceConfig.onMessage?.call(message, type);
  }

  // ============= Security =============

  Future<void> _enableScreenProtector() async {
    try {
      if (Platform.isAndroid) {
        await ScreenProtector.protectDataLeakageOn();
      } else if (Platform.isIOS) {
        await ScreenProtector.preventScreenshotOn();
        await ScreenProtector.protectDataLeakageWithBlur();
      }
    } catch (e) {
      debugPrint('screen_protector enable failed: $e');
    }
  }

  Future<void> _disableScreenProtector() async {
    try {
      if (Platform.isAndroid) {
        await ScreenProtector.protectDataLeakageOff();
      } else if (Platform.isIOS) {
        await ScreenProtector.preventScreenshotOff();
        await ScreenProtector.protectDataLeakageWithBlurOff();
      }
    } catch (e) {
      debugPrint('screen_protector disable failed: $e');
    }
  }

  // ============= Initialization =============

  Future<void> _initializeReader() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      error.value = '';
      errorMessage.value = '';

      debugPrint('PdfReaderController: filePath=$filePath, fileUrl=$fileUrl');

      if (filePath != null && filePath!.isNotEmpty) {
        _resolvedFilePath = filePath;
      } else if (fileUrl != null && fileUrl!.isNotEmpty) {
        _resolvedFilePath = fileUrl;
      }

      debugPrint('PdfReaderController: _resolvedFilePath=$_resolvedFilePath');

      if (_resolvedFilePath == null || _resolvedFilePath!.isEmpty) {
        error.value = 'No file path provided';
        isLoading.value = false;
        return;
      }

      await _loadPdfDocument();
      await _loadTableOfContents();
      await _loadSavedPosition();
      await _loadBookmarks();
      await _loadAnnotations();
      _startReadingSession();

      _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        saveProgress();
      });

      isLoading.value = false;
    } catch (e) {
      hasError.value = true;
      error.value = 'Error initializing reader: $e';
      errorMessage.value = e.toString();
      isLoading.value = false;
    }
  }

  Future<void> loadPdf() async {
    await _initializeReader();
  }

  /// Keep pdfrx's text searcher paired with the active viewer controller.
  /// The searcher caches page text, paints every match, and navigates to the
  /// exact matching bounds instead of merely jumping to a page.
  void _resetPdfViewerController() {
    final previousController = pdfViewerController;
    final previousTransformListener = _pdfViewerTransformListener;
    if (previousController != null && previousTransformListener != null) {
      previousController.removeListener(previousTransformListener);
    }
    _pdfTextSearchListener?.call();
    pdfTextSearcher?.dispose();

    final viewerController = PdfViewerController();
    pdfViewerController = viewerController;
    _pdfViewerTransformListener = () {
      if (viewerController.isReady) {
        zoomLevel.value = viewerController.currentZoom;
      }
    };
    viewerController.addListener(_pdfViewerTransformListener!);

    final searcher = PdfTextSearcher(viewerController);
    pdfTextSearcher = searcher;
    _pdfTextSearchListener = searcher.addListener(_syncPdfSearchState);
  }

  void _syncPdfSearchState() {
    final searcher = pdfTextSearcher;
    if (searcher == null) return;

    searchResults
      ..clear()
      ..addAll(
        searcher.matches.map(
          (match) => PdfTextMatch(
            pageNumber: match.pageNumber,
            startIndex: match.start,
            endIndex: match.end,
            text: match.fragments.map((fragment) => fragment.text).join(),
          ),
        ),
      );

    final currentIndex = searcher.currentIndex;
    if (currentIndex != null && currentIndex >= 0) {
      currentSearchIndex.value = currentIndex;
    }
  }

  Future<void> _loadPdfDocument() async {
    try {
      final isUrl = _resolvedFilePath!.startsWith('http://') ||
          _resolvedFilePath!.startsWith('https://');

      if (isUrl) {
        if (serviceConfig.httpHeaders != null &&
            serviceConfig.httpHeaders!.isNotEmpty) {
          debugPrint('Downloading PDF with custom headers...');
          final downloadedPath =
              await _downloadFileWithHeaders(_resolvedFilePath!);
          if (downloadedPath != null) {
            localFilePath.value = downloadedPath;
            debugPrint('Opening downloaded PDF from: $downloadedPath');
            pdfDocument = await PdfDocument.openFile(downloadedPath);
            debugPrint('PDF document opened successfully');
          } else {
            throw Exception('Failed to download PDF file');
          }
        } else {
          debugPrint('Opening public PDF from URL: $_resolvedFilePath');
          pdfDocument =
              await PdfDocument.openUri(Uri.parse(_resolvedFilePath!));
        }
      } else {
        final file = File(_resolvedFilePath!);
        if (!await file.exists()) {
          throw Exception('PDF file not found at path: $_resolvedFilePath');
        }
        localFilePath.value = _resolvedFilePath;
        debugPrint('Opening local PDF from: $_resolvedFilePath');
        pdfDocument = await PdfDocument.openFile(_resolvedFilePath!);
      }

      totalPages.value = pdfDocument!.pages.length;
      debugPrint('PDF loaded with ${totalPages.value} pages');

      _resetPdfViewerController();
    } catch (e) {
      debugPrint('Exception in _loadPdfDocument: $e');
      throw Exception('Failed to load PDF: $e');
    }
  }

  /// Download file with custom HTTP headers and caching
  Future<String?> _downloadFileWithHeaders(String url) async {
    try {
      loadingProgress.value = 0.0;
      downloadedBytes.value = 0;
      totalBytes.value = 0;

      final fileIdMatch = RegExp(r'/files/(\d+)/').firstMatch(url);
      final fileId = fileIdMatch?.group(1) ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final tempDir = await getTemporaryDirectory();
      final fileName = 'pdf_$fileId.pdf';
      final localPath = '${tempDir.path}/$fileName';

      final cachedFile = File(localPath);
      if (await cachedFile.exists()) {
        final fileSize = await cachedFile.length();
        if (fileSize > 0) {
          debugPrint('Using cached PDF: $localPath ($fileSize bytes)');
          loadingProgress.value = 1.0;
          downloadedBytes.value = fileSize;
          totalBytes.value = fileSize;
          return localPath;
        }
      }

      debugPrint('Downloading PDF from: $url');
      debugPrint('Saving to: $localPath');

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(url));
        // Apply custom headers from service config
        if (serviceConfig.httpHeaders != null) {
          request.headers.addAll(serviceConfig.httpHeaders!);
        }
        request.headers['Accept'] = 'application/pdf';

        final streamedResponse = await client.send(request);

        if (streamedResponse.statusCode == 200) {
          final contentType = streamedResponse.headers['content-type'] ?? '';

          if (contentType.contains('application/json')) {
            final body = await streamedResponse.stream.bytesToString();
            debugPrint('Error: Server returned error instead of PDF file');
            debugPrint('Response: $body');
            throw Exception('Server returned error instead of PDF file');
          }

          final contentLength = streamedResponse.contentLength ?? 0;
          totalBytes.value = contentLength;
          debugPrint('Content-Length: $contentLength bytes');

          final List<int> bytes = [];
          int receivedBytes = 0;

          await for (final chunk in streamedResponse.stream) {
            bytes.addAll(chunk);
            receivedBytes += chunk.length;
            downloadedBytes.value = receivedBytes;

            if (contentLength > 0) {
              loadingProgress.value = receivedBytes / contentLength;
            }
          }

          debugPrint('Downloaded ${bytes.length} bytes');

          final file = File(localPath);
          await file.writeAsBytes(bytes);

          final savedFile = File(localPath);
          if (await savedFile.exists()) {
            final fileSize = await savedFile.length();
            debugPrint('PDF file saved successfully. Size: $fileSize bytes');
          } else {
            debugPrint('ERROR: File was not saved to disk!');
          }

          loadingProgress.value = 1.0;
          return localPath;
        } else if (streamedResponse.statusCode == 401) {
          throw Exception(
              'Authentication required. Please check your credentials.');
        } else if (streamedResponse.statusCode == 403) {
          throw Exception(
              'Access denied. You may not have purchased this book.');
        } else if (streamedResponse.statusCode == 404) {
          throw Exception('PDF file not found on server.');
        } else {
          throw Exception(
              'Download failed with status ${streamedResponse.statusCode}');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      rethrow;
    }
  }

  Future<void> _loadTableOfContents() async {
    try {
      tableOfContents.clear();
    } catch (e) {
      debugPrint('Error loading TOC: $e');
    }
  }

  Future<void> _loadSavedPosition() async {
    final savedPage = _storage.read<int>('pdf_page_$_bookIdForStorage');
    if (savedPage != null && savedPage <= totalPages.value && savedPage > 0) {
      currentPage.value = savedPage;
      _updateProgress();
      _scheduleNavigationWithRetry(savedPage, 0);
      debugPrint(
          '_loadSavedPosition: Scheduled navigation to saved page $savedPage');
    } else {
      currentPage.value = initialPage;
      _updateProgress();
    }
  }

  void _updateProgress() {
    if (totalPages.value > 0) {
      progress.value = currentPage.value / totalPages.value;
      // Sync progress to server if callback provided
      _syncProgressToServer();
    }
  }

  /// Debounced progress sync to avoid excessive API calls on rapid page changes
  DateTime? _lastProgressSync;
  void _syncProgressToServer() {
    final now = DateTime.now();
    if (_lastProgressSync != null &&
        now.difference(_lastProgressSync!).inSeconds < 5) {
      return; // Debounce: sync at most every 5 seconds
    }
    _lastProgressSync = now;
    final callback = serviceConfig.onProgressSync;
    if (callback != null && (bookId ?? 0) > 0 && totalPages.value > 0) {
      callback(
        bookId!,
        progress.value * 100,
        currentPage.value,
        totalPages.value,
      ).catchError((e) {
        debugPrint('Progress sync failed: $e');
      });
    }
  }

  void _loadPreferences() {
    // Use external dark mode if provided, otherwise load from storage
    if (externalDarkMode != null) {
      isDarkMode.value = externalDarkMode!.value;
    } else {
      final savedDarkMode = _storage.read<bool>('pdf_dark_mode');
      if (savedDarkMode != null) isDarkMode.value = savedDarkMode;
    }

    final savedScrollDirection = _storage.read<String>('pdf_scroll_direction');
    if (savedScrollDirection != null) {
      scrollDirection.value = savedScrollDirection == 'horizontal'
          ? Axis.horizontal
          : Axis.vertical;
    }

    final savedAutoScrollInterval =
        _storage.read<int>('pdf_auto_scroll_interval');
    if (savedAutoScrollInterval != null) {
      autoScrollIntervalSeconds.value = savedAutoScrollInterval.clamp(15, 600);
    }

    final savedKeepScreenOn = _storage.read<bool>('pdf_keep_screen_on');
    if (savedKeepScreenOn != null) keepScreenOn.value = savedKeepScreenOn;

    final savedFullscreen = _storage.read<bool>('pdf_fullscreen');
    if (savedFullscreen != null) isFullscreen.value = savedFullscreen;

    final savedRotation = _storage.read<int>('pdf_rotation_quarter_turns');
    if (savedRotation != null) rotationQuarterTurns.value = savedRotation % 4;

    final savedFitMode = _storage.read<String>('pdf_fit_mode');
    if (savedFitMode != null) {
      fitMode.value = PdfFitMode.values.firstWhere(
        (mode) => mode.name == savedFitMode,
        orElse: () => PdfFitMode.page,
      );
    }
  }

  void savePreferences() {
    _storage.write('pdf_dark_mode', isDarkMode.value);
    _storage.write('pdf_scroll_direction',
        scrollDirection.value == Axis.horizontal ? 'horizontal' : 'vertical');
    _storage.write('pdf_auto_scroll_interval', autoScrollIntervalSeconds.value);
    _storage.write('pdf_keep_screen_on', keepScreenOn.value);
    _storage.write('pdf_fullscreen', isFullscreen.value);
    _storage.write('pdf_rotation_quarter_turns', rotationQuarterTurns.value);
    _storage.write('pdf_fit_mode', fitMode.value.name);
  }

  // ============= Session & Progress =============

  void _startReadingSession() {
    _sessionStartTime = DateTime.now();
    if (_bookIdForStorage > 0 && serviceConfig.onSessionStart != null) {
      serviceConfig.onSessionStart!(_bookIdForStorage);
    }
  }

  Future<void> _endReadingSession() async {
    if (isSamplePreview || _sessionStartTime == null) return;

    final duration = DateTime.now().difference(_sessionStartTime!);
    if (duration.inSeconds < 10) return;

    final validBookId = _bookIdForStorage;
    if (validBookId <= 0) {
      debugPrint('Skipping reading session sync - no valid book ID');
      return;
    }

    try {
      // Save progress locally only (not to server — onSessionEnd handles that)
      _storage.write('pdf_page_$_bookIdForStorage', currentPage.value);
      _storage.write('pdf_progress_$_bookIdForStorage', progress.value);

      if (serviceConfig.onSessionEnd != null) {
        await serviceConfig.onSessionEnd!(
          validBookId,
          duration.inSeconds,
          currentPage.value,
          totalPages.value,
        );
      }
    } catch (e) {
      debugPrint('Error ending reading session: $e');
    }
  }

  Future<void> saveProgress() async {
    if (isSamplePreview) return;

    try {
      _storage.write('pdf_page_$_bookIdForStorage', currentPage.value);
      _storage.write('pdf_progress_$_bookIdForStorage', progress.value);

      // Sync progress to server via onProgressSync callback (not onSessionEnd)
      if (_bookIdForStorage > 0 && serviceConfig.onProgressSync != null) {
        await serviceConfig.onProgressSync!(
          _bookIdForStorage,
          progress.value * 100,
          currentPage.value,
          totalPages.value,
        );
      }
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  // ============= Page Navigation =============

  void onPageChanged(int page) {
    currentPage.value = page;
    _updateProgress();
  }

  void goToPage(int page) {
    if (page < 1 || page > totalPages.value) {
      debugPrint(
          'goToPage: Invalid page number $page (total: ${totalPages.value})');
      return;
    }

    if (pdfViewerController == null) {
      debugPrint('goToPage: pdfViewerController is null');
      return;
    }

    currentPage.value = page;
    _updateProgress();

    if (!pdfViewerController!.isReady) {
      debugPrint(
          'goToPage: Controller not ready, scheduling retry for page $page');
      _scheduleNavigationWithRetry(page, 0);
      return;
    }

    try {
      debugPrint(
          'goToPage: Navigating to page $page, scrollDirection: ${scrollDirection.value}');

      pdfViewerController!.goToPage(
        pageNumber: page,
        anchor: PdfPageAnchor.top,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      debugPrint('goToPage: Direct navigation failed ($e), scheduling retry');
      _scheduleNavigationWithRetry(page, 0);
    }
  }

  void _scheduleNavigationWithRetry(int page, int attempt) {
    if (attempt >= 5) {
      debugPrint('goToPage: Max retry attempts reached for page $page');
      return;
    }

    final delayMs = 300 + (attempt * 200);

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (pdfViewerController == null) {
        debugPrint('goToPage: Controller became null, attempt ${attempt + 1}');
        return;
      }

      if (!pdfViewerController!.isReady) {
        debugPrint(
            'goToPage: Controller not ready on attempt ${attempt + 1}, retrying...');
        _scheduleNavigationWithRetry(page, attempt + 1);
        return;
      }

      try {
        pdfViewerController!.goToPage(
          pageNumber: page,
          anchor: PdfPageAnchor.top,
          duration: const Duration(milliseconds: 300),
        );
        debugPrint(
            'goToPage: Successfully navigated to page $page on attempt ${attempt + 1}');
      } catch (e) {
        debugPrint(
            'goToPage: Error on attempt ${attempt + 1}: $e, retrying...');
        _scheduleNavigationWithRetry(page, attempt + 1);
      }
    });
  }

  void goToNextPage() {
    if (currentPage.value < totalPages.value) {
      goToPage(currentPage.value + 1);
    }
  }

  void goToPreviousPage() {
    if (currentPage.value > 1) {
      goToPage(currentPage.value - 1);
    }
  }

  void goToFirstPage() {
    goToPage(1);
  }

  void goToLastPage() {
    goToPage(totalPages.value);
  }

  // ============= Controls =============

  void toggleControls() {
    showControls.value = !showControls.value;
    if (showControls.value) {
      _startControlsHideTimer();
    } else {
      _controlsHideTimer?.cancel();
    }
  }

  void _startControlsHideTimer() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 4), () {
      showControls.value = false;
    });
  }

  // ============= Settings =============

  void setDarkMode(bool value) {
    isDarkMode.value = value;
    savePreferences();
  }

  void setScrollDirection(Axis direction) {
    if (scrollDirection.value == direction) return;

    final pageToRestore = currentPage.value;
    _resetPdfViewerController();
    scrollDirection.value = direction;
    savePreferences();
    _restorePageAfterViewChange(pageToRestore);
  }

  void toggleScrollDirection() {
    final pageToRestore = currentPage.value;
    _resetPdfViewerController();
    scrollDirection.value = scrollDirection.value == Axis.vertical
        ? Axis.horizontal
        : Axis.vertical;
    savePreferences();
    _restorePageAfterViewChange(pageToRestore);
  }

  void _restorePageAfterViewChange(int pageToRestore) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (pdfViewerController != null && pdfViewerController!.isReady) {
        goToPage(pageToRestore);
      } else {
        _scheduleNavigationWithRetry(pageToRestore, 0);
      }
    });
  }

  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;
    if (isFullscreen.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    savePreferences();
  }

  void toggleKeepScreenOn() {
    keepScreenOn.value = !keepScreenOn.value;
  }

  // ============= Search =============

  void enterSearchMode() {
    isSearchMode.value = true;
    showControls.value = false;
    _controlsHideTimer?.cancel();
  }

  void exitSearchMode() {
    isSearchMode.value = false;
    searchQuery.value = '';
    pdfTextSearcher?.resetTextSearch();
    searchResults.clear();
    currentSearchIndex.value = 0;
    showControls.value = true;
  }

  Future<void> performSearch(String query) async {
    if (!featureConfig.enableSearch || pdfTextSearcher == null) {
      searchResults.clear();
      return;
    }

    final normalizedQuery = query.trim();
    searchQuery.value = normalizedQuery;
    searchResults.clear();
    currentSearchIndex.value = 0;

    if (normalizedQuery.isEmpty) {
      pdfTextSearcher!.resetTextSearch();
      return;
    }

    pdfTextSearcher!.startTextSearch(
      normalizedQuery,
      caseInsensitive: true,
      goToFirstMatch: true,
      searchImmediately: true,
    );
  }

  void goToNextSearchResult() {
    pdfTextSearcher?.goToNextMatch();
  }

  void goToPreviousSearchResult() {
    pdfTextSearcher?.goToPrevMatch();
  }

  void toggleAutoScroll() {
    isAutoScrolling.value = !isAutoScrolling.value;
    if (isAutoScrolling.value) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void setAutoScrollInterval(int seconds) {
    autoScrollIntervalSeconds.value = seconds.clamp(15, 600);
    savePreferences();
    if (isAutoScrolling.value) {
      _stopAutoScroll();
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    autoScrollProgress.value = 0.0;
    final intervalMs = autoScrollIntervalSeconds.value * 1000;

    _autoScrollProgressTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) {
      autoScrollProgress.value =
          (autoScrollProgress.value + (100 / intervalMs)).clamp(0.0, 1.0);
    });

    _autoScrollTimer =
        Timer.periodic(Duration(seconds: autoScrollIntervalSeconds.value), (_) {
      if (currentPage.value < totalPages.value) {
        goToNextPage();
        autoScrollProgress.value = 0.0;
      } else {
        toggleAutoScroll();
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollProgressTimer?.cancel();
    autoScrollProgress.value = 0.0;
  }

  void stopAutoScrollOnManualInteraction() {
    if (isAutoScrolling.value) {
      isAutoScrolling.value = false;
      _stopAutoScroll();
    }
  }

  // ============= Zoom =============

  void zoomIn() {
    final controller = pdfViewerController;
    if (controller == null || !controller.isReady) return;
    fitMode.value = PdfFitMode.custom;
    final target = controller.getNextZoom(loop: false).clamp(0.5, 4.0);
    zoomLevel.value = target;
    controller.setZoom(controller.centerPosition, target);
  }

  void zoomOut() {
    final controller = pdfViewerController;
    if (controller == null || !controller.isReady) return;
    fitMode.value = PdfFitMode.custom;
    final target = controller.getPreviousZoom(loop: false).clamp(0.5, 4.0);
    zoomLevel.value = target;
    controller.setZoom(controller.centerPosition, target);
  }

  void resetZoom() {
    final controller = pdfViewerController;
    if (controller == null || !controller.isReady) return;
    fitMode.value = PdfFitMode.custom;
    zoomLevel.value = 1.0;
    controller.setZoom(controller.centerPosition, 1.0);
  }

  void onViewerInteractionUpdate(double gestureScale) {
    if ((gestureScale - 1).abs() > 0.01) {
      fitMode.value = PdfFitMode.custom;
    }
  }

  void onViewerReady(PdfViewerController controller) {
    zoomLevel.value = controller.currentZoom;
    final mode = fitMode.value;
    if (mode != PdfFitMode.custom) {
      Future.microtask(() => applyFitMode(mode));
    }
  }

  Future<void> applyFitMode(PdfFitMode mode) async {
    final controller = pdfViewerController;
    fitMode.value = mode;
    savePreferences();
    if (controller == null ||
        !controller.isReady ||
        mode == PdfFitMode.custom) {
      return;
    }

    final page = currentPage.value.clamp(1, totalPages.value);
    final visualMode = rotationQuarterTurns.value.isOdd
        ? switch (mode) {
            PdfFitMode.width => PdfFitMode.height,
            PdfFitMode.height => PdfFitMode.width,
            _ => mode,
          }
        : mode;

    final destination = switch (visualMode) {
      PdfFitMode.page => controller.calcMatrixForFit(pageNumber: page),
      PdfFitMode.width =>
        controller.calcMatrixFitWidthForPage(pageNumber: page),
      PdfFitMode.height =>
        controller.calcMatrixFitHeightForPage(pageNumber: page),
      PdfFitMode.custom => null,
    };
    await controller.goTo(destination);
    zoomLevel.value = controller.currentZoom;
  }

  void rotateClockwise() {
    rotationQuarterTurns.value = (rotationQuarterTurns.value + 1) % 4;
    savePreferences();
    final mode = fitMode.value;
    if (mode != PdfFitMode.custom) {
      Future.delayed(const Duration(milliseconds: 250), () {
        applyFitMode(mode);
      });
    }
  }

  // ============= Bookmarks =============

  Future<void> _loadBookmarks() async {
    if (_bookIdForStorage <= 0) {
      debugPrint('Skipping bookmarks - no valid book ID');
      return;
    }

    // Try loading from server via callback
    if (serviceConfig.onBookmarksLoad != null) {
      try {
        final serverBookmarks =
            await serviceConfig.onBookmarksLoad!(_bookIdForStorage);
        if (serverBookmarks != null) {
          bookmarkedPages.value = serverBookmarks;
          return;
        }
      } catch (e) {
        debugPrint('Error loading bookmarks from server: $e');
      }
    }

    // Fallback to local storage
    final localBookmarks =
        _storage.read<List<dynamic>>('pdf_bookmarks_$_bookIdForStorage');
    if (localBookmarks != null) {
      bookmarkedPages.value = localBookmarks.cast<int>();
    }
  }

  Future<void> addBookmark([int? page]) async {
    final bookmarkPage = page ?? currentPage.value;

    if (bookmarkedPages.contains(bookmarkPage)) {
      _showMessage('Page $bookmarkPage is already bookmarked',
          ViewerMessageType.warning);
      return;
    }

    bookmarkedPages.add(bookmarkPage);
    bookmarkedPages.sort();
    _storage.write(
        'pdf_bookmarks_$_bookIdForStorage', bookmarkedPages.toList());

    if (_bookIdForStorage > 0 && serviceConfig.onBookmarksSync != null) {
      try {
        await serviceConfig.onBookmarksSync!(
            _bookIdForStorage, bookmarkedPages.toList());
      } catch (e) {
        debugPrint('Error syncing bookmark: $e');
      }
    }

    _showMessage(
        'Bookmark added for page $bookmarkPage', ViewerMessageType.success);
  }

  Future<void> removeBookmark(int page) async {
    bookmarkedPages.remove(page);
    _storage.write(
        'pdf_bookmarks_$_bookIdForStorage', bookmarkedPages.toList());

    if (_bookIdForStorage > 0 && serviceConfig.onBookmarksSync != null) {
      try {
        await serviceConfig.onBookmarksSync!(
            _bookIdForStorage, bookmarkedPages.toList());
      } catch (e) {
        debugPrint('Error removing bookmark from server: $e');
      }
    }

    _showMessage('Bookmark removed', ViewerMessageType.success);
  }

  void toggleBookmark([int? page]) {
    final bookmarkPage = page ?? currentPage.value;
    if (bookmarkedPages.contains(bookmarkPage)) {
      removeBookmark(bookmarkPage);
    } else {
      addBookmark(bookmarkPage);
    }
  }

  void toggleBookmarkForPage(int page) {
    toggleBookmark(page);
  }

  void navigateToBookmark(int page) {
    goToPage(page);
  }

  bool isCurrentPageBookmarked() {
    return bookmarkedPages.contains(currentPage.value);
  }

  Future<void> clearAllBookmarks() async {
    bookmarkedPages.clear();
    _storage.remove('pdf_bookmarks_$_bookIdForStorage');

    if (_bookIdForStorage > 0 && serviceConfig.onBookmarksSync != null) {
      try {
        await serviceConfig.onBookmarksSync!(_bookIdForStorage, []);
      } catch (e) {
        debugPrint('Error clearing all bookmarks: $e');
      }
    }

    _showMessage('All bookmarks cleared', ViewerMessageType.success);
  }

  // ============= Annotations =============

  void toggleAnnotationMode() {
    annotationController.toggleAnnotationMode();
  }

  bool get isAnnotationModeActive =>
      annotationController.isAnnotationMode.value;

  AnnotationType? get selectedAnnotationTool =>
      annotationController.selectedTool.value;

  PageAnnotations getPageAnnotations(int page) {
    return pageAnnotations[page] ?? PageAnnotations(pageNumber: page);
  }

  void addStroke(int page, DrawingStroke stroke,
      {double? refWidth, double? refHeight}) {
    final annotations = getPageAnnotations(page);
    final updatedStrokes = List<DrawingStroke>.from(annotations.strokes)
      ..add(stroke);
    pageAnnotations[page] = annotations.copyWith(
      strokes: updatedStrokes,
      refWidth: refWidth ?? annotations.refWidth,
      refHeight: refHeight ?? annotations.refHeight,
    );

    undoStack.add({
      'type': 'add_stroke',
      'page': page,
      'stroke_id': stroke.id,
    });
    redoStack.clear();

    _saveAnnotationsLocally();
    _syncAnnotationsToServer();
  }

  void removeStroke(int page, String strokeId) {
    final annotations = getPageAnnotations(page);
    final strokeToRemove =
        annotations.strokes.firstWhereOrNull((s) => s.id == strokeId);
    if (strokeToRemove == null) return;

    final updatedStrokes =
        annotations.strokes.where((s) => s.id != strokeId).toList();
    pageAnnotations[page] = annotations.copyWith(strokes: updatedStrokes);

    undoStack.add({
      'type': 'remove_stroke',
      'page': page,
      'stroke': strokeToRemove.toJson(),
    });
    redoStack.clear();

    _saveAnnotationsLocally();
    _syncAnnotationsToServer();
  }

  void addNote(int page, TextNote note, {double? refWidth, double? refHeight}) {
    final annotations = getPageAnnotations(page);
    final updatedNotes = List<TextNote>.from(annotations.notes)..add(note);
    pageAnnotations[page] = annotations.copyWith(
      notes: updatedNotes,
      refWidth: refWidth ?? annotations.refWidth,
      refHeight: refHeight ?? annotations.refHeight,
    );

    undoStack.add({
      'type': 'add_note',
      'page': page,
      'note_id': note.id,
    });
    redoStack.clear();

    _saveAnnotationsLocally();
    _syncAnnotationsToServer();
  }

  void updateNote(int page, TextNote note) {
    final annotations = getPageAnnotations(page);
    final index = annotations.notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;

    final oldNote = annotations.notes[index];
    final updatedNotes = List<TextNote>.from(annotations.notes);
    updatedNotes[index] = note;
    pageAnnotations[page] = annotations.copyWith(notes: updatedNotes);

    undoStack.add({
      'type': 'update_note',
      'page': page,
      'old_note': oldNote.toJson(),
      'new_note': note.toJson(),
    });
    redoStack.clear();

    _saveAnnotationsLocally();
    _syncAnnotationsToServer();
  }

  void removeNote(int page, String noteId) {
    final annotations = getPageAnnotations(page);
    final noteToRemove =
        annotations.notes.firstWhereOrNull((n) => n.id == noteId);
    if (noteToRemove == null) return;

    final updatedNotes =
        annotations.notes.where((n) => n.id != noteId).toList();
    pageAnnotations[page] = annotations.copyWith(notes: updatedNotes);

    undoStack.add({
      'type': 'remove_note',
      'page': page,
      'note': noteToRemove.toJson(),
    });
    redoStack.clear();

    _saveAnnotationsLocally();
    _syncAnnotationsToServer();
  }

  void clearPageAnnotations(int page) {
    final annotations = getPageAnnotations(page);
    if (annotations.strokes.isEmpty && annotations.notes.isEmpty) return;

    undoStack.add({
      'type': 'clear_page',
      'page': page,
      'annotations': annotations.toJson(),
    });
    redoStack.clear();

    pageAnnotations[page] = PageAnnotations(pageNumber: page);

    _saveAnnotationsLocally();
    _syncAnnotationsToServer();
  }

  void highlightSelectedText(int page, String text) {
    if (text.isEmpty) return;

    _showMessage(
      'Text highlighted: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}"',
      ViewerMessageType.success,
    );

    debugPrint('Highlighted text on page $page: $text');
  }

  void addTextNote(int page, String selectedText, String noteContent) {
    if (noteContent.isEmpty) return;
    debugPrint(
        'Note added on page $page for text: "$selectedText" - Note: $noteContent');
  }

  void undoAnnotation() {
    if (undoStack.isEmpty) return;

    final action = undoStack.removeLast();
    final page = action['page'] as int;

    switch (action['type']) {
      case 'add_stroke':
        final strokeId = action['stroke_id'] as String;
        final annotations = getPageAnnotations(page);
        final stroke =
            annotations.strokes.firstWhereOrNull((s) => s.id == strokeId);
        final updatedStrokes =
            annotations.strokes.where((s) => s.id != strokeId).toList();
        pageAnnotations[page] = annotations.copyWith(strokes: updatedStrokes);
        if (stroke != null) {
          redoStack.add({
            'type': 'add_stroke',
            'page': page,
            'stroke': stroke.toJson(),
          });
        }
        break;
      case 'remove_stroke':
        final strokeJson = action['stroke'] as Map<String, dynamic>;
        final stroke = DrawingStroke.fromJson(strokeJson);
        final annotations = getPageAnnotations(page);
        final updatedStrokes = List<DrawingStroke>.from(annotations.strokes)
          ..add(stroke);
        pageAnnotations[page] = annotations.copyWith(strokes: updatedStrokes);
        redoStack.add({
          'type': 'remove_stroke',
          'page': page,
          'stroke_id': stroke.id,
        });
        break;
      case 'add_note':
        final noteId = action['note_id'] as String;
        final annotations = getPageAnnotations(page);
        final note = annotations.notes.firstWhereOrNull((n) => n.id == noteId);
        final updatedNotes =
            annotations.notes.where((n) => n.id != noteId).toList();
        pageAnnotations[page] = annotations.copyWith(notes: updatedNotes);
        if (note != null) {
          redoStack.add({
            'type': 'add_note',
            'page': page,
            'note': note.toJson(),
          });
        }
        break;
      case 'remove_note':
        final noteJson = action['note'] as Map<String, dynamic>;
        final note = TextNote.fromJson(noteJson);
        final annotations = getPageAnnotations(page);
        final updatedNotes = List<TextNote>.from(annotations.notes)..add(note);
        pageAnnotations[page] = annotations.copyWith(notes: updatedNotes);
        redoStack.add({
          'type': 'remove_note',
          'page': page,
          'note_id': note.id,
        });
        break;
      case 'clear_page':
        final annotationsJson = action['annotations'] as Map<String, dynamic>;
        pageAnnotations[page] = PageAnnotations.fromJson(annotationsJson);
        redoStack.add({
          'type': 'clear_page',
          'page': page,
        });
        break;
    }

    _saveAnnotationsLocally();
    _syncAnnotationsToServer();
  }

  void redoAnnotation() {
    if (redoStack.isEmpty) return;

    final action = redoStack.removeLast();
    final page = action['page'] as int;

    switch (action['type']) {
      case 'add_stroke':
        final strokeJson = action['stroke'] as Map<String, dynamic>;
        final stroke = DrawingStroke.fromJson(strokeJson);
        final annotations = getPageAnnotations(page);
        final updatedStrokes = List<DrawingStroke>.from(annotations.strokes)
          ..add(stroke);
        pageAnnotations[page] = annotations.copyWith(strokes: updatedStrokes);
        undoStack.add({
          'type': 'add_stroke',
          'page': page,
          'stroke_id': stroke.id,
        });
        break;
      case 'remove_stroke':
        final strokeId = action['stroke_id'] as String;
        final annotations = getPageAnnotations(page);
        final stroke =
            annotations.strokes.firstWhereOrNull((s) => s.id == strokeId);
        final updatedStrokes =
            annotations.strokes.where((s) => s.id != strokeId).toList();
        pageAnnotations[page] = annotations.copyWith(strokes: updatedStrokes);
        if (stroke != null) {
          undoStack.add({
            'type': 'remove_stroke',
            'page': page,
            'stroke': stroke.toJson(),
          });
        }
        break;
      case 'add_note':
        final noteJson = action['note'] as Map<String, dynamic>;
        final note = TextNote.fromJson(noteJson);
        final annotations = getPageAnnotations(page);
        final updatedNotes = List<TextNote>.from(annotations.notes)..add(note);
        pageAnnotations[page] = annotations.copyWith(notes: updatedNotes);
        undoStack.add({
          'type': 'add_note',
          'page': page,
          'note_id': note.id,
        });
        break;
      case 'remove_note':
        final noteId = action['note_id'] as String;
        final annotations = getPageAnnotations(page);
        final note = annotations.notes.firstWhereOrNull((n) => n.id == noteId);
        final updatedNotes =
            annotations.notes.where((n) => n.id != noteId).toList();
        pageAnnotations[page] = annotations.copyWith(notes: updatedNotes);
        if (note != null) {
          undoStack.add({
            'type': 'remove_note',
            'page': page,
            'note': note.toJson(),
          });
        }
        break;
      case 'clear_page':
        final annotations = getPageAnnotations(page);
        undoStack.add({
          'type': 'clear_page',
          'page': page,
          'annotations': annotations.toJson(),
        });
        pageAnnotations[page] = PageAnnotations(pageNumber: page);
        break;
    }

    _saveAnnotationsLocally();
    _syncAnnotationsToServer();
  }

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  void _saveAnnotationsLocally() {
    final annotationsData = <Map<String, dynamic>>[];
    pageAnnotations.forEach((page, annotations) {
      annotationsData.add(annotations.toJson());
    });
    _storage.write(
        'pdf_annotations_$_bookIdForStorage', jsonEncode(annotationsData));
  }

  Future<void> _loadAnnotations() async {
    // Load from local storage first
    final localData =
        _storage.read<String>('pdf_annotations_$_bookIdForStorage');
    if (localData != null) {
      try {
        final List<dynamic> annotationsList = jsonDecode(localData);
        for (final item in annotationsList) {
          final annotations =
              PageAnnotations.fromJson(item as Map<String, dynamic>);
          pageAnnotations[annotations.pageNumber] = annotations;
        }
      } catch (e) {
        debugPrint('Error loading local annotations: $e');
      }
    }

    // Try to load from server via callback
    if (_bookIdForStorage > 0 && serviceConfig.onAnnotationsLoad != null) {
      try {
        final serverAnnotations =
            await serviceConfig.onAnnotationsLoad!(_bookIdForStorage);
        if (serverAnnotations != null) {
          final List<dynamic>? items =
              serverAnnotations['annotations'] as List<dynamic>?;
          if (items != null) {
            for (final item in items) {
              final pageNumber = item['page_number'] as int;
              final type = item['type'] as String;

              var annotations = pageAnnotations[pageNumber] ??
                  PageAnnotations(pageNumber: pageNumber);

              if (type == 'pen' || type == 'highlighter') {
                final stroke = DrawingStroke(
                  id: item['id']?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  points: (item['points'] as List?)
                          ?.map((p) => DrawPoint.fromJson(p))
                          .toList() ??
                      [],
                  color: Color(item['color'] is int
                      ? item['color']
                      : int.tryParse(item['color']?.toString() ?? '') ??
                          Colors.black.toARGB32()),
                  strokeWidth: (item['stroke_width'] as num?)?.toDouble() ??
                      StrokeWidths.defaultPenWidth,
                  type: type == 'highlighter'
                      ? AnnotationType.highlighter
                      : AnnotationType.pen,
                );
                annotations = annotations
                    .copyWith(strokes: [...annotations.strokes, stroke]);
              } else if (type == 'note') {
                final position = item['position'] as Map<String, dynamic>?;
                final note = TextNote(
                  id: item['id']?.toString() ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  x: (position?['x'] as num?)?.toDouble() ?? 0,
                  y: (position?['y'] as num?)?.toDouble() ?? 0,
                  text: item['text'] as String? ?? '',
                  createdAt: DateTime.now(),
                );
                annotations =
                    annotations.copyWith(notes: [...annotations.notes, note]);
              }

              pageAnnotations[pageNumber] = annotations;
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading annotations from server: $e');
      }
    }
  }

  Future<void> _syncAnnotationsToServer() async {
    if (_bookIdForStorage <= 0 || serviceConfig.onAnnotationsSync == null) {
      return;
    }

    try {
      final annotationsList = <Map<String, dynamic>>[];

      pageAnnotations.forEach((page, annotations) {
        for (final stroke in annotations.strokes) {
          annotationsList.add({
            'page_number': page,
            'type': stroke.type == AnnotationType.highlighter
                ? 'highlighter'
                : 'pen',
            'points': stroke.points.map((p) => p.toJson()).toList(),
            'color': stroke.color.toARGB32(),
            'stroke_width': stroke.strokeWidth,
          });
        }

        for (final note in annotations.notes) {
          annotationsList.add({
            'page_number': page,
            'type': 'note',
            'text': note.text,
            'position': {'x': note.x, 'y': note.y},
          });
        }
      });

      await serviceConfig.onAnnotationsSync!(
          _bookIdForStorage, {'annotations': annotationsList});
    } catch (e) {
      debugPrint('Error syncing annotations: $e');
    }
  }
}

/// Table of contents item model
class TocItem {
  final String title;
  final int? pageNumber;
  final int level;
  final List<TocItem> children;

  TocItem({
    required this.title,
    this.pageNumber,
    this.level = 0,
    this.children = const [],
  });
}

/// PDF text search match result
class PdfTextMatch {
  final int pageNumber;
  final int startIndex;
  final int endIndex;
  final String text;

  PdfTextMatch({
    required this.pageNumber,
    required this.startIndex,
    required this.endIndex,
    required this.text,
  });
}
