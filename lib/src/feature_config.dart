/// Feature flags for enabling/disabling PDF viewer functionalities.
///
/// All features are enabled by default. Set to `false` to disable.
class PdfViewerFeatureConfig {
  /// Enable/disable bookmarks functionality.
  final bool enableBookmarks;

  /// Enable/disable annotations (drawing, notes).
  final bool enableAnnotations;

  /// Enable/disable text search.
  final bool enableSearch;

  /// Enable/disable text selection.
  final bool enableTextSelection;

  /// Enable/disable thumbnail drawer.
  final bool enableThumbnails;

  /// Enable/disable table of contents / outline.
  final bool enableTableOfContents;

  /// Enable/disable auto-scroll feature.
  final bool enableAutoScroll;

  /// Enable/disable dark mode toggle.
  final bool enableDarkModeToggle;

  /// Enable/disable fullscreen toggle.
  final bool enableFullscreen;

  /// Enable/disable page navigation slider.
  final bool enablePageSlider;

  /// Enable/disable DRM screen protection (screenshot/recording prevention).
  final bool enableScreenProtection;

  /// Enable/disable keep-screen-on option.
  final bool enableKeepScreenOn;

  /// Enable/disable reading session tracking.
  final bool enableSessionTracking;

  /// Enable/disable scroll direction toggle (horizontal/vertical).
  final bool enableScrollDirectionToggle;

  /// Enable/disable settings bottom sheet.
  final bool enableSettings;

  /// Enable/disable share functionality.
  final bool enableShare;

  const PdfViewerFeatureConfig({
    this.enableBookmarks = true,
    this.enableAnnotations = true,
    this.enableSearch = true,
    this.enableTextSelection = true,
    this.enableThumbnails = true,
    this.enableTableOfContents = true,
    this.enableAutoScroll = true,
    this.enableDarkModeToggle = true,
    this.enableFullscreen = true,
    this.enablePageSlider = true,
    this.enableScreenProtection = true,
    this.enableKeepScreenOn = true,
    this.enableSessionTracking = true,
    this.enableScrollDirectionToggle = true,
    this.enableSettings = true,
    this.enableShare = true,
  });

  /// All features enabled (default).
  static const PdfViewerFeatureConfig allEnabled = PdfViewerFeatureConfig();

  /// Minimal viewer — only reading, no extras.
  static const PdfViewerFeatureConfig minimal = PdfViewerFeatureConfig(
    enableBookmarks: false,
    enableAnnotations: false,
    enableSearch: false,
    enableTextSelection: false,
    enableThumbnails: false,
    enableTableOfContents: false,
    enableAutoScroll: false,
    enableDarkModeToggle: false,
    enableFullscreen: false,
    enablePageSlider: false,
    enableScreenProtection: false,
    enableKeepScreenOn: false,
    enableSessionTracking: false,
    enableScrollDirectionToggle: false,
    enableSettings: false,
    enableShare: false,
  );

  /// Read-only viewer — reading with navigation, no editing.
  static const PdfViewerFeatureConfig readOnly = PdfViewerFeatureConfig(
    enableBookmarks: false,
    enableAnnotations: false,
    enableSearch: true,
    enableTextSelection: true,
    enableThumbnails: true,
    enableTableOfContents: true,
    enableAutoScroll: true,
    enableDarkModeToggle: true,
    enableFullscreen: true,
    enablePageSlider: true,
    enableScreenProtection: false,
    enableKeepScreenOn: true,
    enableSessionTracking: false,
    enableScrollDirectionToggle: true,
    enableSettings: true,
    enableShare: false,
  );
}
