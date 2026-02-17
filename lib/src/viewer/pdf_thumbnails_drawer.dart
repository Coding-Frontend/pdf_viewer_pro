import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfrx/pdfrx.dart';
import 'pdf_reader_controller.dart';

/// Page thumbnails drawer for PDF reader
class PdfThumbnailsDrawer extends GetView<PdfReaderController> {
  const PdfThumbnailsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;

      return Drawer(
        backgroundColor: bgColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.grid_view, color: textColor),
                    const SizedBox(width: 12),
                    Text(
                      'Pages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${controller.totalPages.value} pages',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                color: isDark ? Colors.white12 : Colors.black12,
                height: 1,
              ),
              Expanded(
                child: controller.pdfDocument == null
                    ? Center(
                        child: Text(
                          'Loading pages...',
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.6)),
                        ),
                      )
                    : Scrollbar(
                        thumbVisibility: true,
                        thickness: 6,
                        radius: const Radius.circular(3),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: controller.totalPages.value,
                          itemBuilder: (context, index) {
                            final pageNum = index + 1;
                            final isCurrentPage =
                                controller.currentPage.value == pageNum;

                            return _ThumbnailItem(
                              pageNumber: pageNum,
                              isSelected: isCurrentPage,
                              isDarkMode: isDark,
                              pdfDocument: controller.pdfDocument,
                              onTap: () {
                                controller.goToPage(pageNum);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ThumbnailItem extends StatefulWidget {
  final int pageNumber;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;
  final PdfDocument? pdfDocument;

  const _ThumbnailItem({
    required this.pageNumber,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
    this.pdfDocument,
  });

  @override
  State<_ThumbnailItem> createState() => _ThumbnailItemState();
}

class _ThumbnailItemState extends State<_ThumbnailItem> {
  ui.Image? _thumbnailImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    if (widget.pdfDocument == null) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      final page = widget.pdfDocument!.pages[widget.pageNumber - 1];
      // Render at a smaller size for thumbnails
      const thumbnailWidth = 150.0;
      final aspectRatio = page.height / page.width;
      final thumbnailHeight = thumbnailWidth * aspectRatio;

      final pdfImage = await page.render(
        width: thumbnailWidth.toInt(),
        height: thumbnailHeight.toInt(),
        fullWidth: thumbnailWidth,
        fullHeight: thumbnailHeight,
        backgroundColor: Colors.white,
      );

      if (pdfImage != null && mounted) {
        // Convert to ui.Image for display
        final uiImage = await pdfImage.createImage();
        if (mounted) {
          setState(() {
            _thumbnailImage = uiImage;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading thumbnail for page ${widget.pageNumber}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _thumbnailImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final bgColor = widget.isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _buildThumbnailContent(textColor),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? primaryColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isSelected)
                    Icon(Icons.check_circle, size: 14, color: primaryColor),
                  if (widget.isSelected) const SizedBox(width: 4),
                  Text(
                    '${widget.pageNumber}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: widget.isSelected ? primaryColor : textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailContent(Color textColor) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_hasError || _thumbnailImage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 32,
              color: textColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 4),
            Text(
              'Page ${widget.pageNumber}',
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Use RawImage widget to display the rendered PDF page
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: RawImage(
        image: _thumbnailImage,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}
