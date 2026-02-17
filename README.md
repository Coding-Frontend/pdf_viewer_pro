# pdf_viewer_pro

A full-featured PDF viewer for Flutter with annotations, bookmarks, DRM protection, search, thumbnails, auto-scroll, and dark/light theme support. Built on PDFium via [pdfrx](https://pub.dev/packages/pdfrx).

## Features

- 📖 **High-performance PDF rendering** using PDFium FFI (pdfrx)
- 🔒 **DRM protection** — screenshot prevention via screen_protector
- 🔖 **Bookmarks** — add, remove, sync with server
- 📝 **Annotations** — pen, highlighter, notes, eraser with undo/redo
- 🔍 **Search** — full-text search with match highlighting
- 🖼️ **Thumbnails** — page thumbnail grid drawer
- 📑 **Table of Contents** — hierarchical TOC navigation
- 🌙 **Dark/Light mode** support
- ↕️ **Vertical/Horizontal** scroll modes
- ⏩ **Auto-scroll** with configurable interval
- 📊 **Progress tracking** — page position persistence
- 🔐 **Authenticated downloads** — token-based file access
- 📤 **Server sync** — optional bookmark/annotation/session sync via callbacks

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  pdf_viewer_pro: ^0.0.1
```

## Usage

### Basic Usage

```dart
import 'package:pdf_viewer_pro/pdf_viewer_pro.dart';

// From a local file
PdfViewerScreen(
  filePath: '/path/to/document.pdf',
  title: 'My Document',
);

// From a URL
PdfViewerScreen(
  filePath: '',
  fileUrl: 'https://example.com/document.pdf',
  title: 'My Document',
);
```

### With Server Sync (Bookmarks, Reading Sessions)

```dart
PdfViewerScreen(
  filePath: '/path/to/document.pdf',
  title: 'My Book',
  bookId: 123,
  enableDrm: true,
  serviceConfig: PdfViewerServiceConfig(
    authToken: 'your-jwt-token',
    onBookmarksSync: (bookId, bookmarks) async {
      // Sync bookmarks to your server
    },
    onAnnotationsSync: (bookId, annotations) async {
      // Sync annotations to your server
    },
    onSessionStart: (bookId) async {
      // Track reading session start
    },
    onSessionEnd: (bookId, duration, lastPage, totalPages) async {
      // Track reading session end
    },
    onMessage: (message, type) {
      // Show toast/snackbar
    },
  ),
);
```

### Simple PDF Viewer (for invoices, receipts)

```dart
// From file
SimplePdfViewer.file('/path/to/invoice.pdf');

// From bytes
SimplePdfViewer.data(pdfBytes);

// From URL
SimplePdfViewer.uri(Uri.parse('https://example.com/doc.pdf'));
```

## License

MIT License
