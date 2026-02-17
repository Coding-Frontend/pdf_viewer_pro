import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pdf_reader_controller.dart';
import 'pdf_bookmarks_sheet.dart';

/// Settings bottom sheet for PDF reader
class PdfSettingsSheet extends GetView<PdfReaderController> {
  const PdfSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;
      final subtitleColor = isDark ? Colors.white60 : Colors.black54;
      final dividerColor = isDark ? Colors.white12 : Colors.black12;
      final primaryColor = Theme.of(context).primaryColor;

      return Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: subtitleColor),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Divider(color: dividerColor, height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('View Mode', textColor),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ViewModeOption(
                                label: 'Vertical',
                                icon: Icons.view_agenda_outlined,
                                isSelected: controller.scrollDirection.value ==
                                    Axis.vertical,
                                onTap: () => controller
                                    .setScrollDirection(Axis.vertical),
                                isDarkMode: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ViewModeOption(
                                label: 'Horizontal',
                                icon: Icons.view_carousel_outlined,
                                isSelected: controller.scrollDirection.value ==
                                    Axis.horizontal,
                                onTap: () => controller
                                    .setScrollDirection(Axis.horizontal),
                                isDarkMode: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSectionHeader('Display', textColor),
                      _SettingsTile(
                        icon: Icons.fullscreen,
                        title: 'Fullscreen Mode',
                        subtitle: 'Hide system bars while reading',
                        trailing: Switch(
                          value: controller.isFullscreen.value,
                          onChanged: (value) => controller.toggleFullscreen(),
                          activeTrackColor: primaryColor,
                        ),
                        isDarkMode: isDark,
                      ),
                      _SettingsTile(
                        icon: Icons.screen_lock_portrait,
                        title: 'Keep Screen On',
                        subtitle: 'Prevent screen from sleeping',
                        trailing: Switch(
                          value: controller.keepScreenOn.value,
                          onChanged: (value) => controller.toggleKeepScreenOn(),
                          activeTrackColor: primaryColor,
                        ),
                        isDarkMode: isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                          'Bookmarks (${controller.bookmarkedPages.length})',
                          textColor),
                      if (controller.bookmarkedPages.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_border,
                                  size: 20, color: subtitleColor),
                              const SizedBox(width: 12),
                              Text(
                                'No bookmarks yet',
                                style: TextStyle(
                                    fontSize: 14, color: subtitleColor),
                              ),
                            ],
                          ),
                        )
                      else
                        ...controller.bookmarkedPages
                            .take(5)
                            .map((page) => ListTile(
                                  dense: true,
                                  leading: Icon(Icons.bookmark,
                                      color: primaryColor, size: 20),
                                  title: Text('Page $page',
                                      style: TextStyle(color: textColor)),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color: subtitleColor, size: 20),
                                    onPressed: () =>
                                        controller.removeBookmark(page),
                                  ),
                                  onTap: () {
                                    controller.goToPage(page);
                                    Get.back();
                                  },
                                )),
                      if (controller.bookmarkedPages.length > 5)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextButton(
                            onPressed: () {
                              Get.back();
                              Get.bottomSheet(
                                const PdfBookmarksSheet(),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                              );
                            },
                            child: Text(
                                'View all ${controller.bookmarkedPages.length} bookmarks'),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ViewModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _ViewModeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = isSelected
        ? primaryColor.withValues(alpha: 0.15)
        : (isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05));
    final borderColor = isSelected ? primaryColor : Colors.transparent;
    final iconColor = isSelected
        ? primaryColor
        : (isDarkMode ? Colors.white70 : Colors.black54);
    final textColor = isSelected
        ? primaryColor
        : (isDarkMode ? Colors.white70 : Colors.black54);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isDarkMode;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;
    final iconColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
