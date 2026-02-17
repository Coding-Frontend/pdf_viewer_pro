import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_viewer_pro/pdf_viewer_pro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PDF Viewer Pro Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Theme configuration
  Color _primaryColor = Colors.blue;
  bool _useDarkMode = false;
  final _darkMode = false.obs;

  // Feature toggles
  bool _enableBookmarks = true;
  bool _enableAnnotations = true;
  bool _enableSearch = true;
  bool _enableThumbnails = true;
  bool _enableAutoScroll = true;
  bool _enableScreenProtection = false;
  bool _enableSettings = true;
  bool _enableFullscreen = true;

  // Theme customization
  Color _lightBg = Colors.white;
  Color _darkBg = const Color(0xFF121212);
  double _cardRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer Pro Example'),
        actions: [
          IconButton(
            icon: Icon(_useDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _useDarkMode = !_useDarkMode;
                _darkMode.value = _useDarkMode;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === Open PDF Button ===
            FilledButton.icon(
              onPressed: _openPdfFromFile,
              icon: const Icon(Icons.file_open),
              label: const Text('Open PDF from Device'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openPdfFromUrl,
              icon: const Icon(Icons.link),
              label: const Text('Open PDF from URL'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openMinimalViewer,
              icon: const Icon(Icons.remove_red_eye),
              label: const Text('Open Minimal Viewer (No Extras)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openSimplePdfViewer,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Open Simple PDF Viewer'),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // === Theme Configuration ===
            const Text(
              'Theme Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Primary color picker
            const Text('Primary Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Colors.blue,
                Colors.red,
                Colors.green,
                Colors.purple,
                Colors.orange,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
              ]
                  .map((color) => GestureDetector(
                        onTap: () => setState(() => _primaryColor = color),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: color,
                          child: _primaryColor == color
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Card border radius
            Row(
              children: [
                const Text('Card Border Radius: '),
                Expanded(
                  child: Slider(
                    value: _cardRadius,
                    min: 0,
                    max: 24,
                    divisions: 12,
                    label: _cardRadius.round().toString(),
                    onChanged: (v) => setState(() => _cardRadius = v),
                  ),
                ),
              ],
            ),

            // Light background color
            const Text('Light Background'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Colors.white,
                const Color(0xFFF5F5F5),
                const Color(0xFFFFF8E1),
                const Color(0xFFE8F5E9),
              ]
                  .map((color) => GestureDetector(
                        onTap: () => setState(() => _lightBg = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: _lightBg == color
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: _lightBg == color ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            // Dark background color
            const SizedBox(height: 8),
            const Text('Dark Background'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                const Color(0xFF121212),
                const Color(0xFF1a1a1a),
                const Color(0xFF212121),
                const Color(0xFF263238),
              ]
                  .map((color) => GestureDetector(
                        onTap: () => setState(() => _darkBg = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: _darkBg == color
                                  ? Colors.blue
                                  : Colors.grey.shade600,
                              width: _darkBg == color ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // === Feature Toggles ===
            const Text(
              'Feature Toggles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _featureSwitch('Bookmarks', _enableBookmarks,
                (v) => setState(() => _enableBookmarks = v)),
            _featureSwitch('Annotations', _enableAnnotations,
                (v) => setState(() => _enableAnnotations = v)),
            _featureSwitch('Search', _enableSearch,
                (v) => setState(() => _enableSearch = v)),
            _featureSwitch('Thumbnails', _enableThumbnails,
                (v) => setState(() => _enableThumbnails = v)),
            _featureSwitch('Auto-scroll', _enableAutoScroll,
                (v) => setState(() => _enableAutoScroll = v)),
            _featureSwitch('Screen Protection', _enableScreenProtection,
                (v) => setState(() => _enableScreenProtection = v)),
            _featureSwitch('Settings Panel', _enableSettings,
                (v) => setState(() => _enableSettings = v)),
            _featureSwitch('Fullscreen', _enableFullscreen,
                (v) => setState(() => _enableFullscreen = v)),
          ],
        ),
      ),
    );
  }

  Widget _featureSwitch(
      String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: onChanged,
    );
  }

  PdfViewerThemeConfig _buildThemeConfig() {
    return PdfViewerThemeConfig(
      primaryColor: _primaryColor,
      lightBackgroundColor: _lightBg,
      darkBackgroundColor: _darkBg,
      cardBorderRadius: _cardRadius,
      bookmarkColor: _primaryColor,
      sliderActiveColor: _primaryColor,
      loadingIndicatorColor: _primaryColor,
    );
  }

  PdfViewerFeatureConfig _buildFeatureConfig() {
    return PdfViewerFeatureConfig(
      enableBookmarks: _enableBookmarks,
      enableAnnotations: _enableAnnotations,
      enableSearch: _enableSearch,
      enableThumbnails: _enableThumbnails,
      enableAutoScroll: _enableAutoScroll,
      enableScreenProtection: _enableScreenProtection,
      enableSettings: _enableSettings,
      enableFullscreen: _enableFullscreen,
    );
  }

  PdfViewerServiceConfig _buildServiceConfig() {
    return PdfViewerServiceConfig(
      isLoggedIn: false,
      onMessage: (message, type) {
        final color = type == ViewerMessageType.error
            ? Colors.red
            : type == ViewerMessageType.warning
                ? Colors.orange
                : Colors.green;
        Get.snackbar(
          type.name.toUpperCase(),
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: color.withValues(alpha: 0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
    );
  }

  Future<void> _openPdfFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      Get.to(() => PdfViewerScreen(
            filePath: result.files.single.path!,
            title: result.files.single.name,
            serviceConfig: _buildServiceConfig(),
            themeConfig: _buildThemeConfig(),
            featureConfig: _buildFeatureConfig(),
            externalDarkMode: _darkMode,
          ));
    }
  }

  void _openPdfFromUrl() {
    // Open with a sample public PDF URL
    Get.to(() => PdfViewerScreen(
          filePath: '',
          fileUrl:
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          title: 'Sample PDF from URL',
          serviceConfig: _buildServiceConfig(),
          themeConfig: _buildThemeConfig(),
          featureConfig: _buildFeatureConfig(),
          externalDarkMode: _darkMode,
        ));
  }

  Future<void> _openMinimalViewer() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      Get.to(() => PdfViewerScreen(
            filePath: result.files.single.path!,
            title: result.files.single.name,
            featureConfig: PdfViewerFeatureConfig.minimal,
            themeConfig: PdfViewerThemeConfig(
              primaryColor: Colors.grey,
              lightBackgroundColor: const Color(0xFFFAFAFA),
              darkBackgroundColor: const Color(0xFF1E1E1E),
            ),
          ));
    }
  }

  Future<void> _openSimplePdfViewer() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      Get.to(() => Scaffold(
            appBar: AppBar(title: Text(result.files.single.name)),
            body: SimplePdfViewer.file(result.files.single.path!),
          ));
    }
  }
}
