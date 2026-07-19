import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/platform_utils.dart';
import '../core/reactive.dart';
import 'pdf_reader_controller.dart';

/// Top navigation bar for PDF reader
class PdfReaderTopBar extends StatelessWidget {
  final PdfReaderController controller;
  final VoidCallback onBack;
  final VoidCallback onOpenThumbnails;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenSettings;
  final VoidCallback? onSearch;

  const PdfReaderTopBar({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onOpenThumbnails,
    required this.onOpenBookmarks,
    required this.onOpenSettings,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;

      return Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: Platform.isIOS ? 44.0 : 56.0,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(ViewerIcons.back, color: textColor),
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Text(
                      controller.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(ViewerIcons.gridView, color: textColor),
                    onPressed: onOpenThumbnails,
                    tooltip: 'Pages',
                  ),
                  if (onSearch != null)
                    IconButton(
                      icon: Icon(ViewerIcons.search, color: textColor),
                      onPressed: onSearch,
                      tooltip: 'Search',
                    ),
                  IconButton(
                    icon: Icon(ViewerIcons.settings, color: textColor),
                    onPressed: onOpenSettings,
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: controller.progress.value,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor:
                  AlwaysStoppedAnimation(Theme.of(context).primaryColor),
              minHeight: 2,
            ),
          ],
        ),
      );
    });
  }
}

/// Bottom navigation bar for PDF reader
class PdfReaderBottomBar extends StatelessWidget {
  final PdfReaderController controller;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onToggleScrollDirection;
  final VoidCallback onGoToPage;

  const PdfReaderBottomBar({
    super.key,
    required this.controller,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onToggleScrollDirection,
    required this.onGoToPage,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;
      final subtitleColor = isDark ? Colors.white60 : Colors.black54;
      // Use a brighter accent color in dark mode for better visibility
      final accentColor =
          isDark ? Colors.white : Theme.of(context).primaryColor;
      final disabledColor = isDark ? Colors.white24 : Colors.black26;

      final canGoPrev = controller.currentPage.value > 1;
      final canGoNext =
          controller.currentPage.value < controller.totalPages.value;

      return Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page slider for quick navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onGoToPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${controller.currentPage.value}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            '/${controller.totalPages.value}',
                            style: TextStyle(
                              fontSize: 13,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Platform.isIOS
                        ? CupertinoSlider(
                            value: controller.currentPage.value
                                .toDouble()
                                .clamp(
                                    1, controller.totalPages.value.toDouble()),
                            min: 1,
                            max: controller.totalPages.value > 0
                                ? controller.totalPages.value.toDouble()
                                : 1,
                            divisions: controller.totalPages.value > 1
                                ? controller.totalPages.value - 1
                                : 1,
                            activeColor: accentColor,
                            onChanged: (value) {
                              controller.goToPage(value.round());
                            },
                          )
                        : SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12),
                              activeTrackColor: accentColor,
                              inactiveTrackColor:
                                  isDark ? Colors.white24 : Colors.black12,
                              thumbColor: accentColor,
                              overlayColor: accentColor.withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: controller.currentPage.value
                                  .toDouble()
                                  .clamp(1,
                                      controller.totalPages.value.toDouble()),
                              min: 1,
                              max: controller.totalPages.value > 0
                                  ? controller.totalPages.value.toDouble()
                                  : 1,
                              divisions: controller.totalPages.value > 1
                                  ? controller.totalPages.value - 1
                                  : 1,
                              onChanged: (value) {
                                controller.goToPage(value.round());
                              },
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(controller.progress.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
            if (controller.featureConfig.enableZoomControls ||
                controller.featureConfig.enableFitControls ||
                controller.featureConfig.enableRotation)
              SizedBox(
                height: 44,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      if (controller.featureConfig.enableZoomControls) ...[
                        _PdfControlButton(
                          icon: Icons.remove,
                          tooltip: 'Zoom out',
                          onTap: controller.zoomLevel.value > 0.5
                              ? controller.zoomOut
                              : null,
                          color: textColor,
                        ),
                        SizedBox(
                          width: 54,
                          child: Text(
                            '${(controller.zoomLevel.value * 100).round()}%',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _PdfControlButton(
                          icon: Icons.add,
                          tooltip: 'Zoom in',
                          onTap: controller.zoomLevel.value < 4
                              ? controller.zoomIn
                              : null,
                          color: textColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (controller.featureConfig.enableFitControls) ...[
                        _PdfControlButton(
                          icon: Icons.fit_screen,
                          tooltip: 'Fit page',
                          onTap: () => controller.applyFitMode(PdfFitMode.page),
                          color: textColor,
                          selected: controller.fitMode.value == PdfFitMode.page,
                          selectedColor: accentColor,
                        ),
                        _PdfControlButton(
                          icon: Icons.swap_horiz,
                          tooltip: 'Fit width',
                          onTap: () =>
                              controller.applyFitMode(PdfFitMode.width),
                          color: textColor,
                          selected:
                              controller.fitMode.value == PdfFitMode.width,
                          selectedColor: accentColor,
                        ),
                        _PdfControlButton(
                          icon: Icons.swap_vert,
                          tooltip: 'Fit height',
                          onTap: () =>
                              controller.applyFitMode(PdfFitMode.height),
                          color: textColor,
                          selected:
                              controller.fitMode.value == PdfFitMode.height,
                          selectedColor: accentColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (controller.featureConfig.enableRotation)
                        _PdfControlButton(
                          icon: Icons.rotate_right,
                          tooltip:
                              'Rotate clockwise (${controller.rotationQuarterTurns.value * 90}°)',
                          onTap: controller.rotateClockwise,
                          color: textColor,
                        ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: canGoPrev ? onPrevPage : null,
                    icon: Icon(
                      ViewerIcons.chevronLeft,
                      color: canGoPrev ? accentColor : disabledColor,
                    ),
                    label: Text(
                      'Previous',
                      style: TextStyle(
                        color: canGoPrev ? accentColor : disabledColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleScrollDirection,
                    icon: Icon(
                      controller.scrollDirection.value == Axis.vertical
                          ? Icons.view_carousel_rounded
                          : Icons.view_day_rounded,
                      color: textColor,
                    ),
                    tooltip: controller.scrollDirection.value == Axis.vertical
                        ? 'Switch to Horizontal'
                        : 'Switch to Vertical',
                  ),
                  TextButton.icon(
                    onPressed: canGoNext ? onNextPage : null,
                    icon: Text(
                      'Next',
                      style: TextStyle(
                        color: canGoNext ? accentColor : disabledColor,
                      ),
                    ),
                    label: Icon(
                      ViewerIcons.chevronRight,
                      color: canGoNext ? accentColor : disabledColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _PdfControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color color;
  final bool selected;
  final Color? selectedColor;

  const _PdfControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.color,
    this.selected = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedColor ?? Theme.of(context).primaryColor;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 40, height: 36),
        style: IconButton.styleFrom(
          backgroundColor:
              selected ? activeColor.withValues(alpha: 0.16) : null,
        ),
        icon: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? color.withValues(alpha: 0.3)
              : selected
                  ? activeColor
                  : color,
        ),
      ),
    );
  }
}

/// Page slider for quick navigation
class PdfPageSlider extends StatelessWidget {
  final PdfReaderController controller;
  const PdfPageSlider({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final textColor = isDark ? Colors.white70 : Colors.black54;
      // Use white accent in dark mode for better visibility
      final accentColor =
          isDark ? Colors.white : Theme.of(context).primaryColor;

      return Container(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: accentColor,
                inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                thumbColor: accentColor,
                overlayColor: accentColor.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: controller.currentPage.value.toDouble(),
                min: 1,
                max: controller.totalPages.value.toDouble(),
                divisions: controller.totalPages.value > 1
                    ? controller.totalPages.value - 1
                    : 1,
                onChanged: (value) {
                  controller.goToPage(value.round());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1', style: TextStyle(fontSize: 12, color: textColor)),
                  Text(
                    'Page ${controller.currentPage.value}',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text('${controller.totalPages.value}',
                      style: TextStyle(fontSize: 12, color: textColor)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
