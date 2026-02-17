import 'package:flutter/material.dart';

/// Theme configuration for the PDF viewer.
///
/// Allows customizing all colors and styles used throughout the viewer.
/// When not specified, sensible defaults are used based on dark/light mode.
class PdfViewerThemeConfig {
  /// Primary accent color (used for buttons, sliders, active items).
  final Color? primaryColor;

  /// Background color in light mode.
  final Color lightBackgroundColor;

  /// Background color in dark mode.
  final Color darkBackgroundColor;

  /// Text color in light mode.
  final Color lightTextColor;

  /// Text color in dark mode.
  final Color darkTextColor;

  /// Subtitle/secondary text color in light mode.
  final Color lightSubtitleColor;

  /// Subtitle/secondary text color in dark mode.
  final Color darkSubtitleColor;

  /// App bar background color in light mode.
  final Color lightAppBarColor;

  /// App bar background color in dark mode.
  final Color darkAppBarColor;

  /// App bar icon/text color in light mode.
  final Color lightAppBarForegroundColor;

  /// App bar icon/text color in dark mode.
  final Color darkAppBarForegroundColor;

  /// Surface/card color in light mode.
  final Color lightSurfaceColor;

  /// Surface/card color in dark mode.
  final Color darkSurfaceColor;

  /// Divider color in light mode.
  final Color lightDividerColor;

  /// Divider color in dark mode.
  final Color darkDividerColor;

  /// Icon color in light mode.
  final Color lightIconColor;

  /// Icon color in dark mode.
  final Color darkIconColor;

  /// Slider active track color.
  final Color? sliderActiveColor;

  /// Slider inactive track color.
  final Color? sliderInactiveColor;

  /// Slider thumb color.
  final Color? sliderThumbColor;

  /// Loading indicator color.
  final Color? loadingIndicatorColor;

  /// Error text color.
  final Color errorColor;

  /// Bookmark icon color.
  final Color? bookmarkColor;

  /// Search highlight color.
  final Color? searchHighlightColor;

  /// Thumbnail selected border color.
  final Color? thumbnailSelectedBorderColor;

  /// Thumbnail background color.
  final Color? thumbnailBackgroundColor;

  /// Border radius for cards and panels.
  final double cardBorderRadius;

  /// Border radius for buttons.
  final double buttonBorderRadius;

  /// Default padding.
  final double defaultPadding;

  const PdfViewerThemeConfig({
    this.primaryColor,
    this.lightBackgroundColor = Colors.white,
    this.darkBackgroundColor = const Color(0xFF121212),
    this.lightTextColor = const Color(0xFF212121),
    this.darkTextColor = Colors.white,
    this.lightSubtitleColor = const Color(0xFF757575),
    this.darkSubtitleColor = const Color(0xFF9E9E9E),
    this.lightAppBarColor = Colors.white,
    this.darkAppBarColor = const Color(0xFF1a1a1a),
    this.lightAppBarForegroundColor = const Color(0xFF212121),
    this.darkAppBarForegroundColor = Colors.white,
    this.lightSurfaceColor = Colors.white,
    this.darkSurfaceColor = const Color(0xFF1a1a1a),
    this.lightDividerColor = const Color(0xFFE0E0E0),
    this.darkDividerColor = const Color(0xFF424242),
    this.lightIconColor = const Color(0xFF757575),
    this.darkIconColor = const Color(0xFFBDBDBD),
    this.sliderActiveColor,
    this.sliderInactiveColor,
    this.sliderThumbColor,
    this.loadingIndicatorColor,
    this.errorColor = Colors.red,
    this.bookmarkColor,
    this.searchHighlightColor,
    this.thumbnailSelectedBorderColor,
    this.thumbnailBackgroundColor,
    this.cardBorderRadius = 12.0,
    this.buttonBorderRadius = 8.0,
    this.defaultPadding = 16.0,
  });

  /// Get background color based on dark mode.
  Color backgroundColor(bool isDark) =>
      isDark ? darkBackgroundColor : lightBackgroundColor;

  /// Get text color based on dark mode.
  Color textColor(bool isDark) => isDark ? darkTextColor : lightTextColor;

  /// Get subtitle color based on dark mode.
  Color subtitleColor(bool isDark) =>
      isDark ? darkSubtitleColor : lightSubtitleColor;

  /// Get app bar color based on dark mode.
  Color appBarColor(bool isDark) => isDark ? darkAppBarColor : lightAppBarColor;

  /// Get app bar foreground color based on dark mode.
  Color appBarForegroundColor(bool isDark) =>
      isDark ? darkAppBarForegroundColor : lightAppBarForegroundColor;

  /// Get surface color based on dark mode.
  Color surfaceColor(bool isDark) =>
      isDark ? darkSurfaceColor : lightSurfaceColor;

  /// Get divider color based on dark mode.
  Color dividerColor(bool isDark) =>
      isDark ? darkDividerColor : lightDividerColor;

  /// Get icon color based on dark mode.
  Color iconColor(bool isDark) => isDark ? darkIconColor : lightIconColor;

  /// Resolve primary color from theme or config.
  Color resolvePrimaryColor(BuildContext context) =>
      primaryColor ?? Theme.of(context).primaryColor;

  /// A default theme config.
  static const PdfViewerThemeConfig defaultTheme = PdfViewerThemeConfig();
}
