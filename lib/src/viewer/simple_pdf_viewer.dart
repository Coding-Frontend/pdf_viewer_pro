import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// A simple, lightweight PDF viewer widget for view-only scenarios.
/// 
/// This widget provides basic PDF viewing capabilities without
/// annotations, bookmarks, or other advanced features.
/// 
/// Use this for invoices, receipts, documents that only need viewing.
/// For full book reading experience, use [PdfViewerScreen] instead.
/// 
/// Usage:
/// ```dart
/// // From file path
/// SimplePdfViewer.file('/path/to/document.pdf')
/// 
/// // From bytes
/// SimplePdfViewer.data(pdfBytes, sourceName: 'document.pdf')
/// 
/// // From URL
/// SimplePdfViewer.uri(Uri.parse('https://example.com/doc.pdf'))
/// ```
class SimplePdfViewer extends StatelessWidget {
  /// The type of source for the PDF
  final _SourceType _sourceType;
  
  /// File path for file-based PDFs
  final String? _filePath;
  
  /// Bytes data for in-memory PDFs
  final Uint8List? _data;
  
  /// Source name for in-memory PDFs
  final String? _sourceName;
  
  /// URI for network/asset PDFs
  final Uri? _uri;
  
  /// Controller for the PDF viewer (optional)
  final PdfViewerController? controller;
  
  /// Background color of the viewer
  final Color? backgroundColor;
  
  /// Whether to enable text selection
  final bool enableTextSelection;
  
  /// Maximum zoom scale
  final double maxScale;
  
  /// Minimum zoom scale
  final double minScale;
  
  /// Whether to show page drop shadow
  final bool showPageShadow;
  
  /// Padding around the PDF content
  final EdgeInsets padding;

  const SimplePdfViewer._({
    super.key,
    required _SourceType sourceType,
    String? filePath,
    Uint8List? data,
    String? sourceName,
    Uri? uri,
    this.controller,
    this.backgroundColor,
    this.enableTextSelection = false,
    this.maxScale = 4.0,
    this.minScale = 0.5,
    this.showPageShadow = true,
    this.padding = const EdgeInsets.all(8),
  }) : _sourceType = sourceType,
       _filePath = filePath,
       _data = data,
       _sourceName = sourceName,
       _uri = uri;

  /// Create a PDF viewer from file path
  factory SimplePdfViewer.file(
    String path, {
    Key? key,
    PdfViewerController? controller,
    Color? backgroundColor,
    bool enableTextSelection = false,
    double maxScale = 4.0,
    double minScale = 0.5,
    bool showPageShadow = true,
    EdgeInsets padding = const EdgeInsets.all(8),
  }) {
    return SimplePdfViewer._(
      key: key,
      sourceType: _SourceType.file,
      filePath: path,
      controller: controller,
      backgroundColor: backgroundColor,
      enableTextSelection: enableTextSelection,
      maxScale: maxScale,
      minScale: minScale,
      showPageShadow: showPageShadow,
      padding: padding,
    );
  }

  /// Create a PDF viewer from bytes data
  factory SimplePdfViewer.data(
    Uint8List data, {
    required String sourceName,
    Key? key,
    PdfViewerController? controller,
    Color? backgroundColor,
    bool enableTextSelection = false,
    double maxScale = 4.0,
    double minScale = 0.5,
    bool showPageShadow = true,
    EdgeInsets padding = const EdgeInsets.all(8),
  }) {
    return SimplePdfViewer._(
      key: key,
      sourceType: _SourceType.data,
      data: data,
      sourceName: sourceName,
      controller: controller,
      backgroundColor: backgroundColor,
      enableTextSelection: enableTextSelection,
      maxScale: maxScale,
      minScale: minScale,
      showPageShadow: showPageShadow,
      padding: padding,
    );
  }

  /// Create a PDF viewer from URI
  factory SimplePdfViewer.uri(
    Uri uri, {
    Key? key,
    PdfViewerController? controller,
    Color? backgroundColor,
    bool enableTextSelection = false,
    double maxScale = 4.0,
    double minScale = 0.5,
    bool showPageShadow = true,
    EdgeInsets padding = const EdgeInsets.all(8),
  }) {
    return SimplePdfViewer._(
      key: key,
      sourceType: _SourceType.uri,
      uri: uri,
      controller: controller,
      backgroundColor: backgroundColor,
      enableTextSelection: enableTextSelection,
      maxScale: maxScale,
      minScale: minScale,
      showPageShadow: showPageShadow,
      padding: padding,
    );
  }

  PdfViewerParams _buildParams(bool isDark, Color bgColor) {
    return PdfViewerParams(
      backgroundColor: bgColor,
      enableTextSelection: enableTextSelection,
      scrollByMouseWheel: 1.0,
      maxScale: maxScale,
      minScale: minScale,
      panAxis: PanAxis.free,
      boundaryMargin: padding,
      pageDropShadow: showPageShadow
          ? BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
              blurRadius: 8,
              offset: const Offset(2, 2),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? (isDark ? const Color(0xFF1a1a1a) : const Color(0xFFF5F5F5));

    switch (_sourceType) {
      case _SourceType.file:
        return PdfViewer.file(
          _filePath!,
          controller: controller,
          params: _buildParams(isDark, bgColor),
        );
      case _SourceType.data:
        return PdfViewer.data(
          _data!,
          sourceName: _sourceName!,
          controller: controller,
          params: _buildParams(isDark, bgColor),
        );
      case _SourceType.uri:
        return PdfViewer.uri(
          _uri!,
          controller: controller,
          params: _buildParams(isDark, bgColor),
        );
    }
  }
}

enum _SourceType { file, data, uri }
