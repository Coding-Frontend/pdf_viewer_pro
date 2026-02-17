import 'package:flutter/material.dart';

/// Types of annotations supported
enum AnnotationType {
  pen,
  highlighter,
  note,
  eraser;

  String get label {
    switch (this) {
      case AnnotationType.pen:
        return 'Pen';
      case AnnotationType.highlighter:
        return 'Highlight';
      case AnnotationType.note:
        return 'Note';
      case AnnotationType.eraser:
        return 'Eraser';
    }
  }

  IconData get icon {
    switch (this) {
      case AnnotationType.pen:
        return Icons.edit;
      case AnnotationType.highlighter:
        return Icons.highlight;
      case AnnotationType.note:
        return Icons.note_add;
      case AnnotationType.eraser:
        return Icons.auto_fix_normal;
    }
  }
}

/// A single point in a drawing stroke
class DrawPoint {
  final double x;
  final double y;
  final double? pressure;

  const DrawPoint(this.x, this.y, {this.pressure});

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        if (pressure != null) 'pressure': pressure,
      };

  factory DrawPoint.fromJson(Map<String, dynamic> json) => DrawPoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        pressure: json['pressure'] != null
            ? (json['pressure'] as num).toDouble()
            : null,
      );
}

/// A drawing stroke (pen or highlighter)
class DrawingStroke {
  final String id;
  final List<DrawPoint> points;
  final Color color;
  final double strokeWidth;
  final AnnotationType type;

  DrawingStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'color': color.toARGB32(),
        'stroke_width': strokeWidth,
        'type': type.name,
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) => DrawingStroke(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        points: (json['points'] as List)
            .map((p) => DrawPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        color: Color(json['color'] as int),
        strokeWidth: (json['stroke_width'] as num).toDouble(),
        type: AnnotationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => AnnotationType.pen,
        ),
      );
}

/// A text note annotation
class TextNote {
  final String id;
  final double x;
  final double y;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TextNote({
    required this.id,
    required this.x,
    required this.y,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'text': text,
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  factory TextNote.fromJson(Map<String, dynamic> json) => TextNote(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        text: json['text'] as String,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  TextNote copyWith({
    String? id,
    double? x,
    double? y,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TextNote(
        id: id ?? this.id,
        x: x ?? this.x,
        y: y ?? this.y,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Page annotations container
/// Stores annotations in normalized coordinates (0-1 range) for zoom independence
class PageAnnotations {
  final int pageNumber;
  final List<DrawingStroke> strokes;
  final List<TextNote> notes;

  /// Reference size when annotations were created (for backward compatibility)
  final double? refWidth;
  final double? refHeight;

  PageAnnotations({
    required this.pageNumber,
    List<DrawingStroke>? strokes,
    List<TextNote>? notes,
    this.refWidth,
    this.refHeight,
  })  : strokes = strokes ?? [],
        notes = notes ?? [];

  Map<String, dynamic> toJson() => {
        'page_number': pageNumber,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        if (refWidth != null) 'ref_width': refWidth,
        if (refHeight != null) 'ref_height': refHeight,
      };

  factory PageAnnotations.fromJson(Map<String, dynamic> json) =>
      PageAnnotations(
        pageNumber: json['page_number'] as int,
        strokes: (json['strokes'] as List?)
            ?.map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
            .toList(),
        notes: (json['notes'] as List?)
            ?.map((n) => TextNote.fromJson(n as Map<String, dynamic>))
            .toList(),
        refWidth: json['ref_width'] != null
            ? (json['ref_width'] as num).toDouble()
            : null,
        refHeight: json['ref_height'] != null
            ? (json['ref_height'] as num).toDouble()
            : null,
      );

  PageAnnotations copyWith({
    int? pageNumber,
    List<DrawingStroke>? strokes,
    List<TextNote>? notes,
    double? refWidth,
    double? refHeight,
  }) =>
      PageAnnotations(
        pageNumber: pageNumber ?? this.pageNumber,
        strokes: strokes ?? List.from(this.strokes),
        notes: notes ?? List.from(this.notes),
        refWidth: refWidth ?? this.refWidth,
        refHeight: refHeight ?? this.refHeight,
      );

  /// Scale strokes to fit the current canvas size
  List<DrawingStroke> getScaledStrokes(
      double currentWidth, double currentHeight) {
    if (refWidth == null || refHeight == null) return strokes;
    if (strokes.isEmpty) return strokes;

    final scaleX = currentWidth / refWidth!;
    final scaleY = currentHeight / refHeight!;

    return strokes.map((stroke) {
      final scaledPoints = stroke.points.map((p) {
        return DrawPoint(p.x * scaleX, p.y * scaleY, pressure: p.pressure);
      }).toList();
      return DrawingStroke(
        id: stroke.id,
        points: scaledPoints,
        color: stroke.color,
        strokeWidth: stroke.strokeWidth * scaleX, // Scale stroke width too
        type: stroke.type,
      );
    }).toList();
  }

  /// Scale notes to fit the current canvas size
  List<TextNote> getScaledNotes(double currentWidth, double currentHeight) {
    if (refWidth == null || refHeight == null) return notes;
    if (notes.isEmpty) return notes;

    final scaleX = currentWidth / refWidth!;
    final scaleY = currentHeight / refHeight!;

    return notes.map((note) {
      return note.copyWith(
        x: note.x * scaleX,
        y: note.y * scaleY,
      );
    }).toList();
  }
}

/// Color presets for annotations
class AnnotationColors {
  static const List<Color> penColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  static const List<Color> highlightColors = [
    Color(0x80FFFF00), // Yellow
    Color(0x8000FF00), // Green
    Color(0x80FF69B4), // Pink
    Color(0x8000BFFF), // Blue
    Color(0x80FFA500), // Orange
    Color(0x80DA70D6), // Orchid
  ];

  static const Color defaultPenColor = Colors.black;
  static const Color defaultHighlightColor = Color(0x80FFFF00);
}

/// Stroke width presets
class StrokeWidths {
  static const double thin = 2.0;
  static const double medium = 4.0;
  static const double thick = 6.0;
  static const double extraThick = 10.0;

  static const List<double> presets = [thin, medium, thick, extraThick];
  static const double defaultPenWidth = medium;
  static const double defaultHighlightWidth = extraThick * 2;
}
