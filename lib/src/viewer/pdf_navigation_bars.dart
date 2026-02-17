import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pdf_reader_controller.dart';

/// Top navigation bar for PDF reader
class PdfReaderTopBar extends GetView<PdfReaderController> {
  final VoidCallback onBack;
  final VoidCallback onOpenThumbnails;
  final VoidCallback onOpenBookmarks;
  final VoidCallback onOpenSettings;
  final VoidCallback? onSearch;

  const PdfReaderTopBar({
    super.key,
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
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
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
                    icon: Icon(Icons.grid_view, color: textColor),
                    onPressed: onOpenThumbnails,
                    tooltip: 'Pages',
                  ),
                  if (onSearch != null)
                    IconButton(
                      icon: Icon(Icons.search, color: textColor),
                      onPressed: onSearch,
                      tooltip: 'Search',
                    ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: textColor),
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
class PdfReaderBottomBar extends GetView<PdfReaderController> {
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onToggleScrollDirection;
  final VoidCallback onGoToPage;

  const PdfReaderBottomBar({
    super.key,
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
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: accentColor,
                        inactiveTrackColor:
                            isDark ? Colors.white24 : Colors.black12,
                        thumbColor: accentColor,
                        overlayColor: accentColor.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: controller.currentPage.value
                            .toDouble()
                            .clamp(1, controller.totalPages.value.toDouble()),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: canGoPrev ? onPrevPage : null,
                    icon: Icon(
                      Icons.chevron_left,
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
                      Icons.chevron_right,
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

/// Page slider for quick navigation
class PdfPageSlider extends GetView<PdfReaderController> {
  const PdfPageSlider({super.key});

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
