/// PDF Viewer Pro - A full-featured PDF viewer for Flutter
///
/// Built on PDFium (pdfrx) with support for annotations, bookmarks,
/// DRM protection, search, thumbnails, auto-scroll, and dark mode.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:pdf_viewer_pro/pdf_viewer_pro.dart';
///
/// PdfViewerScreen(
///   filePath: '/path/to/document.pdf',
///   title: 'My Document',
/// );
/// ```
///
/// ## With Server Sync
///
/// ```dart
/// PdfViewerScreen(
///   filePath: '/path/to/document.pdf',
///   title: 'My Book',
///   bookId: 123,
///   serviceConfig: PdfViewerServiceConfig(
///     authToken: 'your-jwt-token',
///     isLoggedIn: true,
///     onBookmarksSync: (bookId, bookmarks) async { /* sync */ },
///     onMessage: (msg, type) { /* show toast */ },
///   ),
/// );
/// ```
library;

// Service configuration (abstraction layer for server sync)
export 'src/service_config.dart';

// Theme configuration
export 'src/viewer_theme_config.dart';

// Feature configuration
export 'src/feature_config.dart';

// Annotation models & widgets
export 'src/annotations/annotation_models.dart';
export 'src/annotations/annotation_toolbar.dart';
export 'src/annotations/annotation_canvas.dart';

// PDF viewer components
export 'src/viewer/pdf_viewer_screen.dart';
export 'src/viewer/pdf_reader_controller.dart';
export 'src/viewer/pdf_navigation_bars.dart';
export 'src/viewer/pdf_settings_sheet.dart';
export 'src/viewer/pdf_bookmarks_sheet.dart';
export 'src/viewer/pdf_thumbnails_drawer.dart';
export 'src/viewer/pdf_search_overlay.dart';
export 'src/viewer/pdf_text_selection_toolbar.dart';
export 'src/viewer/simple_pdf_viewer.dart';
