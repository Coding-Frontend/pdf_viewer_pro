# pdf_viewer_pro

[![pub.dev](https://img.shields.io/pub/v/pdf_viewer_pro.svg)](https://pub.dev/packages/pdf_viewer_pro)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-green)](https://pub.dev/packages/pdf_viewer_pro)
[![Publisher](https://img.shields.io/badge/publisher-codingfrontend.in-blue)](https://pub.dev/publishers/codingfrontend.in)

A full-featured PDF viewer for Flutter **(Android & iOS)** with annotations, bookmarks, DRM protection, search, thumbnails, auto-scroll, and dark/light theme support. Built on PDFium via [pdfrx](https://pub.dev/packages/pdfrx).

## Platform Support

| Android | iOS |
|:-------:|:---:|
|    ✅    |  ✅  |

## Features

- 📄 **High-performance PDF rendering** using PDFium FFI (pdfrx)
- 🔖 **Bookmarks** — add, remove, navigate, sync with server
- ✏️ **Annotations** — pen drawing, highlighter, notes, eraser with undo/redo
- 🔤 **Text Selection** — select and copy PDF text
- 🔍 **Search** — full-text search with match highlighting
- 🖼️ **Thumbnails** — page thumbnail grid drawer
- 📒 **Table of Contents** — hierarchical PDF outline navigation
- 🌙 **Dark/Light** theme support
- ↔️ **Scroll direction** — toggle vertical/horizontal scroll
- ⏩ **Auto-scroll** with configurable interval
- 📊 **Page slider** — bottom navigation bar with page preview
- 🔒 **DRM protection** — screenshot/screen-recording prevention
- ☀️ **Keep screen on** while reading
- 📊 **Session tracking** — reading duration and page progress
- 🔗 **Authenticated downloads** via custom HTTP headers
- ☁️ **Server sync** via callbacks (bookmarks, annotations, sessions)
- 💾 **Custom storage** — pluggable storage backend
- 📤 **Share** — share PDF or content
- 🪶 **SimplePdfViewer** — lightweight view-only widget for invoices/docs

## Screenshots

<div align="center">
  <p>
    <img src="screenshots/pdf_home.svg" alt="PDF Home" width="640" />
    <img src="screenshots/pdf_reader.svg" alt="PDF Reader" width="640" />
  </p>
  <p>
    <img src="screenshots/pdf_thumbnails.svg" alt="PDF Thumbnails" width="360" />
    <img src="screenshots/pdf_toc.svg" alt="PDF TOC" width="360" />
    <img src="screenshots/pdf_search.svg" alt="PDF Search" width="360" />
  </p>
  <p>
    <img src="screenshots/pdf_annotations.svg" alt="PDF Annotations" width="360" />
    <img src="screenshots/pdf_bookmarks.svg" alt="PDF Bookmarks" width="360" />
    <img src="screenshots/pdf_darkmode.svg" alt="PDF Dark Mode" width="360" />
  </p>
  <p>
    <img src="screenshots/pdf_share.svg" alt="PDF Share" width="720" />
  </p>
</div>


## Getting Started

```yaml
dependencies:
  pdf_viewer_pro: ^0.0.2
```

## Basic Usage

```dart
import 'package:pdf_viewer_pro/pdf_viewer_pro.dart';

// Open from file path
Navigator.push(context, MaterialPageRoute(
  builder: (_) => PdfViewerScreen(
    filePath: '/path/to/document.pdf',
    title: 'My Document',
  ),
));

// Open from URL
Navigator.push(context, MaterialPageRoute(
  builder: (_) => PdfViewerScreen(
    fileUrl: 'https://example.com/document.pdf',
    title: 'My Document',
  ),
));
```

## Feature Configuration

```dart
PdfViewerScreen(
  filePath: '/path/to/document.pdf',
  title: 'My Document',
  bookId: 42,                       // For bookmarks/annotations persistence
  featureConfig: PdfViewerFeatureConfig(
    enableBookmarks: true,
    enableAnnotations: true,
    enableSearch: true,
    enableTextSelection: true,
    enableThumbnails: true,
    enableTableOfContents: true,
    enableAutoScroll: true,
    enableDarkModeToggle: true,
    enableFullscreen: true,
    enablePageSlider: true,
    enableScreenProtection: false,
    enableKeepScreenOn: true,
    enableSessionTracking: true,
    enableScrollDirectionToggle: true,
    enableSettings: true,
    enableShare: true,
  ),
);
```

## Built-in Presets

```dart
// All features enabled
featureConfig: PdfViewerFeatureConfig.fullFeatures

// View-only (no annotations/bookmarks)
featureConfig: PdfViewerFeatureConfig.readOnly

// Bare minimum (page slider only)
featureConfig: PdfViewerFeatureConfig.minimal
```

## Simple View-Only Widget

For invoices, receipts, and documents that only need viewing:

```dart
// From file path
SimplePdfViewer.file('/path/to/invoice.pdf')

// From bytes
SimplePdfViewer.data(pdfBytes, sourceName: 'invoice.pdf')

// From URL
SimplePdfViewer.uri(Uri.parse('https://example.com/doc.pdf'))
```

## Theme Customization

```dart
themeConfig: PdfViewerThemeConfig(
  primaryColor: Colors.blue,
  lightBackgroundColor: Colors.white,
  darkBackgroundColor: Color(0xFF121212),
  cardBorderRadius: 12.0,
),
```

## Server Sync

```dart
serviceConfig: PdfViewerServiceConfig(
  // Sync bookmarks with your server
  onBookmarksSync: (bookId, bookmarks) async {
    await myApi.saveBookmarks(bookId, bookmarks);
  },
  onBookmarksLoad: (bookId) async {
    return await myApi.loadBookmarks(bookId);
  },
  // Track reading sessions
  onSessionStart: (bookId) async {
    await myApi.startSession(bookId);
  },
  onSessionEnd: (bookId, durationSeconds, currentPage, totalPages) async {
    await myApi.endSession(bookId, durationSeconds);
  },
  // Authenticated file access
  httpHeaders: {'Authorization': 'Bearer $token'},
),
```