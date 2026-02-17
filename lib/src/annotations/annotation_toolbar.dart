import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'annotation_models.dart';

/// Annotation toolbar controller
class AnnotationToolbarController extends GetxController {
  final isAnnotationMode = false.obs;
  final selectedTool = Rx<AnnotationType?>(null);
  final selectedPenColor = AnnotationColors.defaultPenColor.obs;
  final selectedHighlightColor = AnnotationColors.defaultHighlightColor.obs;
  final selectedStrokeWidth = StrokeWidths.defaultPenWidth.obs;
  final showColorPicker = false.obs;
  final showStrokePicker = false.obs;
  final penOpacity = 1.0.obs; // Opacity from 0.0 to 1.0

  void toggleAnnotationMode() {
    isAnnotationMode.value = !isAnnotationMode.value;
    if (!isAnnotationMode.value) {
      selectedTool.value = null;
      showColorPicker.value = false;
      showStrokePicker.value = false;
    }
  }

  void selectTool(AnnotationType? tool) {
    if (selectedTool.value == tool) {
      // Tapping same tool toggles off
      selectedTool.value = null;
    } else {
      selectedTool.value = tool;
    }
    showColorPicker.value = false;
    showStrokePicker.value = false;
  }

  void setColor(Color color) {
    if (selectedTool.value == AnnotationType.highlighter) {
      selectedHighlightColor.value = color;
    } else {
      selectedPenColor.value = color;
    }
    showColorPicker.value = false;
  }

  void setOpacity(double opacity) {
    penOpacity.value = opacity.clamp(0.1, 1.0);
  }

  void setStrokeWidth(double width) {
    selectedStrokeWidth.value = width;
    showStrokePicker.value = false;
  }

  void toggleColorPicker() {
    showColorPicker.value = !showColorPicker.value;
    showStrokePicker.value = false;
  }

  void toggleStrokePicker() {
    showStrokePicker.value = !showStrokePicker.value;
    showColorPicker.value = false;
  }

  Color get currentColor {
    final baseColor = selectedTool.value == AnnotationType.highlighter
        ? selectedHighlightColor.value
        : selectedPenColor.value;
    // Apply opacity to pen color
    if (selectedTool.value == AnnotationType.pen) {
      return baseColor.withValues(alpha: penOpacity.value);
    }
    return baseColor;
  }

  List<Color> get availableColors =>
      selectedTool.value == AnnotationType.highlighter
          ? AnnotationColors.highlightColors
          : AnnotationColors.penColors;
}

/// Annotation toolbar widget
class AnnotationToolbar extends StatelessWidget {
  final AnnotationToolbarController controller;
  final bool isDarkMode;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onClear;
  final bool canUndo;
  final bool canRedo;

  const AnnotationToolbar({
    super.key,
    required this.controller,
    required this.isDarkMode,
    this.onUndo,
    this.onRedo,
    this.onClear,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = isDarkMode ? const Color(0xFF2a2a2a) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Obx(() {
      if (!controller.isAnnotationMode.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main toolbar - scrollable to prevent overflow
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pen tool
                  _ToolButton(
                    icon: AnnotationType.pen.icon,
                    label: AnnotationType.pen.label,
                    isSelected:
                        controller.selectedTool.value == AnnotationType.pen,
                    onTap: () => controller.selectTool(AnnotationType.pen),
                    isDarkMode: isDarkMode,
                    primaryColor: primaryColor,
                  ),
                  // Note tool
                  _ToolButton(
                    icon: AnnotationType.note.icon,
                    label: AnnotationType.note.label,
                    isSelected:
                        controller.selectedTool.value == AnnotationType.note,
                    onTap: () => controller.selectTool(AnnotationType.note),
                    isDarkMode: isDarkMode,
                    primaryColor: primaryColor,
                  ),
                  // Eraser tool
                  _ToolButton(
                    icon: AnnotationType.eraser.icon,
                    label: AnnotationType.eraser.label,
                    isSelected:
                        controller.selectedTool.value == AnnotationType.eraser,
                    onTap: () => controller.selectTool(AnnotationType.eraser),
                    isDarkMode: isDarkMode,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 32,
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(width: 8),
                  // Color picker (for pen)
                  if (controller.selectedTool.value == AnnotationType.pen) ...[
                    _ColorButton(
                      color: controller.currentColor,
                      isSelected: controller.showColorPicker.value,
                      onTap: controller.toggleColorPicker,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 4),
                    // Stroke width picker
                    _StrokeButton(
                      strokeWidth: controller.selectedStrokeWidth.value,
                      isSelected: controller.showStrokePicker.value,
                      onTap: controller.toggleStrokePicker,
                      isDarkMode: isDarkMode,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Undo/Redo/Clear buttons
                  IconButton(
                    icon: Icon(
                      Icons.undo,
                      color: canUndo
                          ? textColor
                          : (isDarkMode ? Colors.white38 : Colors.black26),
                      size: 22,
                    ),
                    onPressed: canUndo ? onUndo : null,
                    tooltip: 'Undo',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.redo,
                      color: canRedo
                          ? textColor
                          : (isDarkMode ? Colors.white38 : Colors.black26),
                      size: 22,
                    ),
                    onPressed: canRedo ? onRedo : null,
                    tooltip: 'Redo',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.delete_outline, color: textColor, size: 22),
                    onPressed: onClear,
                    tooltip: 'Clear page',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Color picker dropdown
            if (controller.showColorPicker.value)
              _ColorPickerRow(
                colors: controller.availableColors,
                selectedColor: controller.currentColor,
                onColorSelected: controller.setColor,
                isDarkMode: isDarkMode,
                opacity: controller.penOpacity.value,
                onOpacityChanged:
                    controller.selectedTool.value == AnnotationType.pen
                        ? controller.setOpacity
                        : null,
                showOpacity:
                    controller.selectedTool.value == AnnotationType.pen,
              ),
            // Stroke width picker dropdown
            if (controller.showStrokePicker.value)
              _StrokePickerRow(
                strokeWidths: StrokeWidths.presets,
                selectedWidth: controller.selectedStrokeWidth.value,
                onWidthSelected: controller.setStrokeWidth,
                isDarkMode: isDarkMode,
                primaryColor: primaryColor,
              ),
          ],
        ),
      );
    });
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;
  final Color primaryColor;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border:
                isSelected ? Border.all(color: primaryColor, width: 1.5) : null,
          ),
          child: Icon(
            icon,
            size: 22,
            color: isSelected
                ? primaryColor
                : (isDarkMode ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Color',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: isDarkMode ? Colors.white54 : Colors.black38,
                    width: 1.5)
                : null,
          ),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode ? Colors.white38 : Colors.black26,
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrokeButton extends StatelessWidget {
  final double strokeWidth;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;
  final Color primaryColor;

  const _StrokeButton({
    required this.strokeWidth,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Stroke size',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: isDarkMode ? Colors.white54 : Colors.black38,
                    width: 1.5)
                : null,
          ),
          child: SizedBox(
            width: 22,
            height: 22,
            child: Center(
              child: Container(
                width: strokeWidth.clamp(4.0, 14.0),
                height: strokeWidth.clamp(4.0, 14.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool isDarkMode;
  final double opacity;
  final ValueChanged<double>? onOpacityChanged;
  final bool showOpacity;

  const _ColorPickerRow({
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    required this.isDarkMode,
    this.opacity = 1.0,
    this.onOpacityChanged,
    this.showOpacity = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: colors.map((color) {
              // Get base color without opacity for comparison
              final baseSelected = Color.fromARGB(255, selectedColor.r.toInt(),
                  selectedColor.g.toInt(), selectedColor.b.toInt());
              final baseColor = Color.fromARGB(
                  255, color.r.toInt(), color.g.toInt(), color.b.toInt());
              final isSelected =
                  baseColor.toARGB32() == baseSelected.toARGB32();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onColorSelected(color),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? (isDarkMode ? Colors.white : Colors.black)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          // Opacity slider (only for pen tool)
          if (showOpacity && onOpacityChanged != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Opacity',
                    style: TextStyle(fontSize: 12, color: textColor),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: selectedColor,
                        inactiveTrackColor:
                            selectedColor.withValues(alpha: 0.3),
                        thumbColor: selectedColor,
                      ),
                      child: Slider(
                        value: opacity,
                        min: 0.1,
                        max: 1.0,
                        onChanged: onOpacityChanged,
                      ),
                    ),
                  ),
                  Text(
                    '${(opacity * 100).round()}%',
                    style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StrokePickerRow extends StatelessWidget {
  final List<double> strokeWidths;
  final double selectedWidth;
  final ValueChanged<double> onWidthSelected;
  final bool isDarkMode;
  final Color primaryColor;

  const _StrokePickerRow({
    required this.strokeWidths,
    required this.selectedWidth,
    required this.onWidthSelected,
    required this.isDarkMode,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: strokeWidths.map((width) {
          final isSelected = width == selectedWidth;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: () => onWidthSelected(width),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: width.clamp(4.0, 20.0),
                    height: width.clamp(4.0, 20.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
