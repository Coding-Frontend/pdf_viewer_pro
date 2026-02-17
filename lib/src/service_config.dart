/// Message types for viewer notifications
enum ViewerMessageType {
  success,
  error,
  warning,
  info,
}

/// Callback type for displaying messages (toast/snackbar)
typedef MessageCallback = void Function(String message, ViewerMessageType type);

/// Callback for bookmark sync
typedef BookmarksSyncCallback = Future<List<int>?> Function(
    int bookId, List<int> bookmarks);

/// Callback for annotation sync
typedef AnnotationsSyncCallback = Future<Map<String, dynamic>?> Function(
    int bookId, Map<String, dynamic> annotations);

/// Callback for loading bookmarks from server
typedef BookmarksLoadCallback = Future<List<int>?> Function(int bookId);

/// Callback for loading annotations from server
typedef AnnotationsLoadCallback = Future<Map<String, dynamic>?> Function(
    int bookId);

/// Callback for reading session start
typedef SessionStartCallback = Future<void> Function(int bookId);

/// Callback for reading session end
typedef SessionEndCallback = Future<void> Function(
    int bookId, int durationSeconds, int lastPage, int totalPages);

/// Configuration for optional server-side services.
///
/// All callbacks are optional. When not provided, the viewer works
/// fully offline with local storage only.
class PdfViewerServiceConfig {
  /// JWT or bearer token for authenticated file downloads.
  final String? authToken;

  /// Called when bookmarks should be synced to the server.
  final BookmarksSyncCallback? onBookmarksSync;

  /// Called when annotations should be synced to the server.
  final AnnotationsSyncCallback? onAnnotationsSync;

  /// Called to load bookmarks from the server.
  final BookmarksLoadCallback? onBookmarksLoad;

  /// Called to load annotations from the server.
  final AnnotationsLoadCallback? onAnnotationsLoad;

  /// Called when a reading session starts.
  final SessionStartCallback? onSessionStart;

  /// Called when a reading session ends.
  final SessionEndCallback? onSessionEnd;

  /// Called to display a message to the user.
  final MessageCallback? onMessage;

  /// Whether the user is logged in (enables server sync features).
  final bool isLoggedIn;

  const PdfViewerServiceConfig({
    this.authToken,
    this.onBookmarksSync,
    this.onAnnotationsSync,
    this.onBookmarksLoad,
    this.onAnnotationsLoad,
    this.onSessionStart,
    this.onSessionEnd,
    this.onMessage,
    this.isLoggedIn = false,
  });

  /// A default config with no server sync (offline only).
  static const PdfViewerServiceConfig offline = PdfViewerServiceConfig();
}
