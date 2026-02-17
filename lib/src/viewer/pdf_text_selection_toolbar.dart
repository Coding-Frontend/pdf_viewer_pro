import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'pdf_reader_controller.dart';

/// Toolbar that appears when text is selected in PDF viewer
class PdfTextSelectionToolbar extends StatelessWidget {
  final String selectedText;
  final int pageNumber;
  final VoidCallback onHighlight;
  final VoidCallback onAddNote;
  final VoidCallback onDismiss;
  final Offset position;

  const PdfTextSelectionToolbar({
    super.key,
    required this.selectedText,
    required this.pageNumber,
    required this.onHighlight,
    required this.onAddNote,
    required this.onDismiss,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<PdfReaderController>().isDarkMode.value;
    final bgColor = isDark ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    return Positioned(
      left: position.dx - 60, // Center the toolbar
      top: position.dy - 60, // Position above selection
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolButton(
                icon: Icons.highlight,
                label: 'Highlight',
                onTap: onHighlight,
                color: Colors.yellow.shade700,
                isDarkMode: isDark,
              ),
              const SizedBox(width: 4),
              _ToolButton(
                icon: Icons.note_add,
                label: 'Note',
                onTap: onAddNote,
                color: primaryColor,
                isDarkMode: isDark,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.close, color: textColor, size: 20),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isDarkMode;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
