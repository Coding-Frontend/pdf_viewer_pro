import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pdf_reader_controller.dart';

/// Bookmarks bottom sheet for PDF reader
class PdfBookmarksSheet extends GetView<PdfReaderController> {
  const PdfBookmarksSheet({super.key});

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
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
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
                      'Bookmarks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Row(
                      children: [
                        if (controller.bookmarkedPages.isNotEmpty)
                          TextButton.icon(
                            onPressed: () =>
                                _showClearAllDialog(context, isDark),
                            icon: Icon(Icons.delete_sweep,
                                size: 18, color: Colors.red[400]),
                            label: Text('Clear all',
                                style: TextStyle(color: Colors.red[400])),
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: subtitleColor),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(color: dividerColor, height: 1),
              Expanded(
                child: controller.bookmarkedPages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              size: 64,
                              color: subtitleColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bookmarks yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the bookmark icon to save pages',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: controller.bookmarkedPages.length,
                        itemBuilder: (context, index) {
                          final pageNum = controller.bookmarkedPages[index];
                          return _BookmarkTile(
                            pageNumber: pageNum,
                            totalPages: controller.totalPages.value,
                            isDarkMode: isDark,
                            primaryColor: primaryColor,
                            onTap: () {
                              controller.goToPage(pageNum);
                              Get.back();
                            },
                            onDelete: () => controller.toggleBookmark(pageNum),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showClearAllDialog(BuildContext context, bool isDark) {
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    Get.dialog(
      AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear All Bookmarks?', style: TextStyle(color: textColor)),
        content: Text(
          'This will remove all your bookmarked pages. This action cannot be undone.',
          style: TextStyle(color: textColor.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              controller.clearAllBookmarks();
              Get.back();
            },
            child: Text('Clear All', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final int pageNumber;
  final int totalPages;
  final bool isDarkMode;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkTile({
    required this.pageNumber,
    required this.totalPages,
    required this.isDarkMode,
    required this.primaryColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;
    final bgColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    final progress = (pageNumber / totalPages * 100).toStringAsFixed(1);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDarkMode ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 24,
                    color: subtitleColor,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pageNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Page $pageNumber',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.bookmark, size: 14, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '$progress% through document',
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon:
                  Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
              onPressed: onDelete,
              tooltip: 'Remove bookmark',
            ),
          ],
        ),
      ),
    );
  }
}

/// Table of Contents sheet for PDF reader
class PdfTocSheet extends GetView<PdfReaderController> {
  const PdfTocSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;
      final subtitleColor = isDark ? Colors.white60 : Colors.black54;
      final dividerColor = isDark ? Colors.white12 : Colors.black12;

      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
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
                      'Contents',
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
              Expanded(
                child: controller.tableOfContents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list_alt_outlined,
                              size: 64,
                              color: subtitleColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No table of contents',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This document has no outline',
                              style: TextStyle(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: controller.tableOfContents.length,
                        itemBuilder: (context, index) {
                          final item = controller.tableOfContents[index];
                          return _TocItemTile(
                            item: item,
                            isDarkMode: isDark,
                            onTap: () {
                              if (item.pageNumber != null) {
                                controller.goToPage(item.pageNumber!);
                                Get.back();
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _TocItemTile extends StatelessWidget {
  final TocItem item;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _TocItemTile({
    required this.item,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white60 : Colors.black54;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0 + (item.level * 16),
          right: 16,
          top: 12,
          bottom: 12,
        ),
        child: Row(
          children: [
            if (item.level > 0)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: subtitleColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: item.level == 0 ? 15 : 14,
                  fontWeight:
                      item.level == 0 ? FontWeight.w600 : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
            if (item.pageNumber != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.pageNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
