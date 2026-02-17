import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pdf_reader_controller.dart';

/// Google Drive style search overlay for PDF viewer
/// Shows a top search bar with results minimap on the right side
class PdfSearchOverlay extends GetView<PdfReaderController> {
  final VoidCallback onClose;

  const PdfSearchOverlay({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = controller.isDarkMode.value;
      final bgColor = isDark ? const Color(0xFF1a1a1a) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;
      final subtitleColor = isDark ? Colors.white60 : Colors.black54;

      // Only return the search bar - minimap is now in the parent Stack
      return SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: onClose,
                    ),
                    Expanded(
                      child: _SearchTextField(
                        isDarkMode: isDark,
                        textColor: textColor,
                        onSearch: (query) => controller.performSearch(query),
                      ),
                    ),
                  ],
                ),
              ),
              // Search results navigation bar (when there are results)
              if (controller.searchResults.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${controller.currentSearchIndex.value + 1} of ${controller.searchResults.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_up, color: textColor),
                        onPressed: controller.goToPreviousSearchResult,
                        tooltip: 'Previous result',
                      ),
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down, color: textColor),
                        onPressed: controller.goToNextSearchResult,
                        tooltip: 'Next result',
                      ),
                    ],
                  ),
                ),
              // Show "No results" message when search is done but no results
              if (controller.searchQuery.isNotEmpty &&
                  controller.searchResults.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_off, color: subtitleColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _SearchTextField extends StatefulWidget {
  final bool isDarkMode;
  final Color textColor;
  final Function(String) onSearch;

  const _SearchTextField({
    required this.isDarkMode,
    required this.textColor,
    required this.onSearch,
  });

  @override
  State<_SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<_SearchTextField> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);
    final hintColor = widget.isDarkMode ? Colors.white54 : Colors.black45;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        style: TextStyle(color: widget.textColor, fontSize: 16),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search in document',
          hintStyle: TextStyle(color: hintColor, fontSize: 16),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(Icons.search, color: hintColor, size: 22),
          suffixIcon: _textController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: hintColor, size: 20),
                  onPressed: () {
                    _textController.clear();
                    widget.onSearch('');
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
          // Debounced search
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_textController.text == value) {
              widget.onSearch(value);
            }
          });
        },
        onSubmitted: (value) {
          widget.onSearch(value);
        },
      ),
    );
  }
}
