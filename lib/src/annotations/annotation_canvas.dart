import 'package:flutter/material.dart';
import 'annotation_models.dart';

/// Custom painter for drawing annotations
class AnnotationPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final List<TextNote> notes;
  final bool showNoteMarkers;
  final VoidCallback? onNoteMarkerTapped;
  final Offset? eraserPosition;
  final bool showEraser;

  AnnotationPainter({
    required this.strokes,
    this.currentStroke,
    required this.notes,
    this.showNoteMarkers = true,
    this.onNoteMarkerTapped,
    this.eraserPosition,
    this.showEraser = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke being drawn
    if (currentStroke != null && currentStroke!.points.isNotEmpty) {
      _drawStroke(canvas, currentStroke!);
    }

    // Draw note markers
    if (showNoteMarkers) {
      for (final note in notes) {
        _drawNoteMarker(canvas, note);
      }
    }

    // Draw eraser indicator
    if (showEraser && eraserPosition != null) {
      _drawEraserIndicator(canvas, eraserPosition!);
    }
  }

  void _drawEraserIndicator(Canvas canvas, Offset position) {
    const eraserRadius = 20.0;

    // Draw eraser circle outline
    final outlinePaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(position, eraserRadius, outlinePaint);

    // Draw semi-transparent fill
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, eraserRadius, fillPaint);
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Use blend mode for highlighter
    if (stroke.type == AnnotationType.highlighter) {
      paint.blendMode = BlendMode.multiply;
    }

    if (stroke.points.length == 1) {
      // Draw a dot for single point
      final point = stroke.points.first;
      canvas.drawCircle(
        Offset(point.x, point.y),
        stroke.strokeWidth / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      // Draw path for multiple points
      final path = Path();
      path.moveTo(stroke.points.first.x, stroke.points.first.y);

      for (int i = 1; i < stroke.points.length; i++) {
        final p1 = stroke.points[i];

        // Use quadratic bezier for smoother lines
        if (i < stroke.points.length - 1) {
          final p2 = stroke.points[i + 1];
          final midX = (p1.x + p2.x) / 2;
          final midY = (p1.y + p2.y) / 2;
          path.quadraticBezierTo(p1.x, p1.y, midX, midY);
        } else {
          path.lineTo(p1.x, p1.y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawNoteMarker(Canvas canvas, TextNote note) {
    const markerSize = 24.0;
    final offset = Offset(note.x, note.y);

    // Draw shadow
    canvas.drawCircle(
      offset.translate(1, 1),
      markerSize / 2,
      Paint()..color = Colors.black26,
    );

    // Draw marker background
    canvas.drawCircle(
      offset,
      markerSize / 2,
      Paint()..color = Colors.amber,
    );

    // Draw note icon
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '📝',
        style: TextStyle(fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      offset.translate(-iconPainter.width / 2, -iconPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        currentStroke != oldDelegate.currentStroke ||
        notes != oldDelegate.notes ||
        eraserPosition != oldDelegate.eraserPosition ||
        showEraser != oldDelegate.showEraser;
  }
}

/// Drawing canvas overlay for annotations
class AnnotationCanvas extends StatefulWidget {
  final Size canvasSize;
  final AnnotationType? activeTool;
  final Color penColor;
  final Color highlightColor;
  final double strokeWidth;
  final List<DrawingStroke> strokes;
  final List<TextNote> notes;
  final ValueChanged<DrawingStroke> onStrokeCompleted;
  final ValueChanged<Offset> onNoteRequested;
  final ValueChanged<String> onEraseStroke;
  final ValueChanged<TextNote> onNoteTapped;
  final bool enabled;

  const AnnotationCanvas({
    super.key,
    required this.canvasSize,
    required this.activeTool,
    required this.penColor,
    required this.highlightColor,
    required this.strokeWidth,
    required this.strokes,
    required this.notes,
    required this.onStrokeCompleted,
    required this.onNoteRequested,
    required this.onEraseStroke,
    required this.onNoteTapped,
    this.enabled = true,
  });

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  DrawingStroke? _currentStroke;
  List<DrawPoint> _currentPoints = [];
  Offset? _eraserPosition; // Track eraser position for visual feedback

  @override
  Widget build(BuildContext context) {
    // Note markers are now rendered as widgets, not via CustomPaint
    final noteMarkers = _buildNoteMarkers();

    if (!widget.enabled || widget.activeTool == null) {
      // Display mode - show strokes and clickable note markers
      return Stack(
        children: [
          // Drawing strokes layer - ignore pointer for scrolling
          IgnorePointer(
            child: CustomPaint(
              size: widget.canvasSize,
              painter: AnnotationPainter(
                strokes: widget.strokes,
                notes: widget.notes,
                showNoteMarkers: false, // We'll render notes as widgets
              ),
            ),
          ),
          // Note markers layer - clickable
          ...noteMarkers,
        ],
      );
    }

    return Stack(
      children: [
        // Drawing canvas with gesture detection
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTapUp: _onTapUp,
          child: CustomPaint(
            size: widget.canvasSize,
            painter: AnnotationPainter(
              strokes: widget.strokes,
              currentStroke: _currentStroke,
              notes: widget.notes,
              showNoteMarkers: false, // We'll render notes as widgets
              eraserPosition: _eraserPosition,
              showEraser: widget.activeTool == AnnotationType.eraser,
            ),
          ),
        ),
        // Note markers layer - clickable
        ...noteMarkers,
      ],
    );
  }

  /// Build Figma-style note markers as widgets
  List<Widget> _buildNoteMarkers() {
    final markers = <Widget>[];

    for (int i = 0; i < widget.notes.length; i++) {
      final note = widget.notes[i];
      markers.add(
        Positioned(
          left: note.x - 14, // Center the 28px marker
          top: note.y - 14,
          child: _NoteMarkerWidget(
            note: note,
            index: i + 1,
            onTap: () => widget.onNoteTapped(note),
          ),
        ),
      );
    }

    return markers;
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.activeTool == AnnotationType.note) return;
    if (widget.activeTool == AnnotationType.eraser) {
      setState(() {
        _eraserPosition = details.localPosition;
      });
      _handleErase(details.localPosition);
      return;
    }

    final point = DrawPoint(
      details.localPosition.dx,
      details.localPosition.dy,
    );
    _currentPoints = [point];

    final color = widget.activeTool == AnnotationType.highlighter
        ? widget.highlightColor
        : widget.penColor;

    final strokeWidth = widget.activeTool == AnnotationType.highlighter
        ? StrokeWidths.defaultHighlightWidth
        : widget.strokeWidth;

    setState(() {
      _currentStroke = DrawingStroke(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: _currentPoints,
        color: color,
        strokeWidth: strokeWidth,
        type: widget.activeTool!,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.activeTool == AnnotationType.note) return;
    if (widget.activeTool == AnnotationType.eraser) {
      setState(() {
        _eraserPosition = details.localPosition;
      });
      _handleErase(details.localPosition);
      return;
    }

    if (_currentStroke == null) return;

    final point = DrawPoint(
      details.localPosition.dx,
      details.localPosition.dy,
    );
    _currentPoints.add(point);

    setState(() {
      _currentStroke = DrawingStroke(
        id: _currentStroke!.id,
        points: List.from(_currentPoints),
        color: _currentStroke!.color,
        strokeWidth: _currentStroke!.strokeWidth,
        type: _currentStroke!.type,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.activeTool == AnnotationType.note) return;
    if (widget.activeTool == AnnotationType.eraser) {
      // Clear eraser position when done
      setState(() {
        _eraserPosition = null;
      });
      return;
    }

    if (_currentStroke != null && _currentPoints.isNotEmpty) {
      widget.onStrokeCompleted(_currentStroke!);
    }

    setState(() {
      _currentStroke = null;
      _currentPoints = [];
    });
  }

  void _onTapUp(TapUpDetails details) {
    final position = details.localPosition;

    if (widget.activeTool == AnnotationType.note) {
      widget.onNoteRequested(Offset(position.dx, position.dy));
      return;
    }

    if (widget.activeTool == AnnotationType.eraser) {
      _handleErase(position);
      return;
    }

    // Check if tapping on an existing note
    for (final note in widget.notes) {
      final noteOffset = Offset(note.x, note.y);
      if ((noteOffset - position).distance < 20) {
        widget.onNoteTapped(note);
        return;
      }
    }
  }

  void _handleErase(Offset position) {
    const eraseRadius = 20.0;

    for (final stroke in widget.strokes) {
      for (final point in stroke.points) {
        final pointOffset = Offset(point.x, point.y);
        if ((pointOffset - position).distance < eraseRadius) {
          widget.onEraseStroke(stroke.id);
          return;
        }
      }
    }
  }
}

/// Dialog for creating/editing notes
class NoteDialog extends StatefulWidget {
  final TextNote? existingNote;
  final Offset position;

  const NoteDialog({
    super.key,
    this.existingNote,
    required this.position,
  });

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.existingNote?.text ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingNote != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Note' : 'Add Note'),
      content: TextField(
        controller: _textController,
        maxLines: 5,
        minLines: 3,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter your note...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () => Navigator.of(context).pop({'action': 'delete'}),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_textController.text.trim().isNotEmpty) {
              Navigator.of(context).pop({
                'action': 'save',
                'note': TextNote(
                  id: widget.existingNote?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  x: widget.position.dx,
                  y: widget.position.dy,
                  text: _textController.text.trim(),
                  createdAt: widget.existingNote?.createdAt ?? DateTime.now(),
                  updatedAt: isEditing ? DateTime.now() : null,
                ),
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Figma-style note marker widget
class _NoteMarkerWidget extends StatefulWidget {
  final TextNote note;
  final int index;
  final VoidCallback onTap;

  const _NoteMarkerWidget({
    required this.note,
    required this.index,
    required this.onTap,
  });

  @override
  State<_NoteMarkerWidget> createState() => _NoteMarkerWidgetState();
}

class _NoteMarkerWidgetState extends State<_NoteMarkerWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isExpanded) {
          // If already expanded, tap opens the edit dialog
          widget.onTap();
        } else {
          // First tap expands to show the note content
          setState(() => _isExpanded = true);
        }
      },
      onLongPress: widget.onTap, // Long press always opens edit dialog
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: BoxConstraints(
          maxWidth: _isExpanded ? 200 : 28,
          minWidth: 28,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF5865F2), // Discord/Figma-like blue
          borderRadius: BorderRadius.circular(_isExpanded ? 12 : 14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      child: Text(
        '${widget.index}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return TapRegion(
      onTapOutside: (_) => setState(() => _isExpanded = false),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.index}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Note',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = false),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.note.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDate(widget.note.createdAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
