import 'package:flutter/material.dart';
import 'package:get/get.dart'
    hide Rx, RxBool, RxInt, RxDouble, RxString, RxList, RxMap, Obx, Worker;
import 'package:get_storage/get_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_viewer_pro/pdf_viewer_pro.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _darkMode = RxBool(false);
  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
          title: 'PDF Viewer Pro Demo',
          theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
          darkTheme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true, brightness: Brightness.dark),
          themeMode: _darkMode.value ? ThemeMode.dark : ThemeMode.light,
          home: HomePage(appDarkMode: _darkMode),
        ));
  }
}

class HomePage extends StatefulWidget {
  final RxBool appDarkMode;
  const HomePage({super.key, required this.appDarkMode});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Theme
  Color _primaryColor = Colors.blue;
  Color _lightBg = Colors.white;
  Color _darkBg = const Color(0xFF121212);
  double _cardRadius = 12.0;
  // Features
  bool _enableBookmarks = true, _enableAnnotations = true, _enableSearch = true;
  bool _enableTextSelection = true, _enableThumbnails = true, _enableTOC = true;
  bool _enableAutoScroll = true, _enableDarkModeToggle = true, _enableFullscreen = true;
  bool _enablePageSlider = true, _enableScreenProtection = false;
  bool _enableKeepScreenOn = true, _enableSessionTracking = true;
  bool _enableScrollDirectionToggle = true, _enableSettings = true, _enableShare = true;
  // Service
  bool _enableCustomAuth = false;
  final _apiKeyController = TextEditingController(text: 'your-api-key');
  final _bookIdController = TextEditingController(text: '0');

  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); }

  @override
  void dispose() { _tabController.dispose(); _apiKeyController.dispose(); _bookIdController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer Pro'),
        centerTitle: true,
        actions: [
          Obx(() => IconButton(
                icon: Icon(widget.appDarkMode.value ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => widget.appDarkMode.value = !widget.appDarkMode.value,
              )),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.tune), text: 'Features'),
          Tab(icon: Icon(Icons.palette), text: 'Theme'),
          Tab(icon: Icon(Icons.cloud_sync), text: 'Service'),
        ]),
      ),
      body: SafeArea(
        child: Column(children: [
          _buildOpenButtons(),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              _buildFeaturesTab(),
              _buildThemeTab(),
              _buildServiceTab(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildOpenButtons() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: FilledButton.icon(onPressed: _openFromFile, icon: const Icon(Icons.file_open, size: 18), label: const Text('Open PDF File'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(onPressed: _openFromUrl, icon: const Icon(Icons.link, size: 18), label: const Text('Open from URL'))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: _openMinimal, icon: const Icon(Icons.remove_red_eye, size: 18), label: const Text('Minimal Viewer'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: _openSimple, icon: const Icon(Icons.picture_as_pdf, size: 18), label: const Text('Simple Viewer'))),
      ]),
    ]),
  );

  Widget _buildFeaturesTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('Quick Presets'),
    Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: () => _applyPreset('all'), icon: const Icon(Icons.check_circle, size: 16, color: Colors.green), label: const Text('All', style: TextStyle(color: Colors.green, fontSize: 12)))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () => _applyPreset('minimal'), icon: const Icon(Icons.minimize, size: 16, color: Colors.orange), label: const Text('Minimal', style: TextStyle(color: Colors.orange, fontSize: 12)))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () => _applyPreset('readOnly'), icon: const Icon(Icons.chrome_reader_mode, size: 16, color: Colors.blue), label: const Text('Read-Only', style: TextStyle(color: Colors.blue, fontSize: 12)))),
    ]),
    const SizedBox(height: 16),
    _sectionHeader('Book Configuration'),
    TextFormField(controller: _bookIdController, decoration: const InputDecoration(labelText: 'Book ID (for bookmarks/annotations storage)', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.book)), keyboardType: TextInputType.number),
    const SizedBox(height: 16),
    _sectionHeader('Reading & Annotations'),
    _featureSwitch('Bookmarks', 'Save and navigate to specific pages', Icons.bookmark, _enableBookmarks, (v) => setState(() => _enableBookmarks = v)),
    _featureSwitch('Annotations', 'Drawing, highlights, and text annotations', Icons.edit, _enableAnnotations, (v) => setState(() => _enableAnnotations = v)),
    _featureSwitch('Text Selection', 'Select and copy PDF text', Icons.text_fields, _enableTextSelection, (v) => setState(() => _enableTextSelection = v)),
    _featureSwitch('Share', 'Share PDF or extracted content', Icons.share, _enableShare, (v) => setState(() => _enableShare = v)),
    const SizedBox(height: 16),
    _sectionHeader('Navigation'),
    _featureSwitch('Thumbnails', 'Side drawer with page thumbnail preview', Icons.view_column, _enableThumbnails, (v) => setState(() => _enableThumbnails = v)),
    _featureSwitch('Table of Contents', 'PDF outline/bookmarks navigation', Icons.list, _enableTOC, (v) => setState(() => _enableTOC = v)),
    _featureSwitch('Search', 'Full-text search within PDF', Icons.search, _enableSearch, (v) => setState(() => _enableSearch = v)),
    _featureSwitch('Page Slider', 'Bottom page navigation slider', Icons.linear_scale, _enablePageSlider, (v) => setState(() => _enablePageSlider = v)),
    _featureSwitch('Auto-scroll', 'Automatic continuous scrolling', Icons.play_arrow, _enableAutoScroll, (v) => setState(() => _enableAutoScroll = v)),
    _featureSwitch('Scroll Direction', 'Toggle horizontal/vertical scroll', Icons.swap_horiz, _enableScrollDirectionToggle, (v) => setState(() => _enableScrollDirectionToggle = v)),
    const SizedBox(height: 16),
    _sectionHeader('Display Controls'),
    _featureSwitch('Dark Mode Toggle', 'Light/Dark theme switch', Icons.dark_mode, _enableDarkModeToggle, (v) => setState(() => _enableDarkModeToggle = v)),
    _featureSwitch('Fullscreen', 'Hide system UI while reading', Icons.fullscreen, _enableFullscreen, (v) => setState(() => _enableFullscreen = v)),
    _featureSwitch('Settings Panel', 'Bottom sheet with display options', Icons.settings, _enableSettings, (v) => setState(() => _enableSettings = v)),
    const SizedBox(height: 16),
    _sectionHeader('Security & Tracking'),
    _featureSwitch('Screen Protection', 'Prevent screenshots/recording (DRM)', Icons.security, _enableScreenProtection, (v) => setState(() => _enableScreenProtection = v)),
    _featureSwitch('Keep Screen On', 'Prevent device from sleeping', Icons.brightness_high, _enableKeepScreenOn, (v) => setState(() => _enableKeepScreenOn = v)),
    _featureSwitch('Session Tracking', 'Track reading duration and page progress', Icons.analytics, _enableSessionTracking, (v) => setState(() => _enableSessionTracking = v)),
    const SizedBox(height: 24),
  ]);

  Widget _buildThemeTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('Accent / Primary Color'),
    _colorRow([Colors.blue, Colors.deepPurple, Colors.red, Colors.green, Colors.orange, Colors.teal, Colors.pink, Colors.indigo], _primaryColor, (c) => setState(() => _primaryColor = c)),
    const SizedBox(height: 16),
    _sectionHeader('Light Background'),
    _colorRow([Colors.white, const Color(0xFFF5F5F5), const Color(0xFFFFF8E1), const Color(0xFFE8F5E9), const Color(0xFFE3F2FD)], _lightBg, (c) => setState(() => _lightBg = c)),
    const SizedBox(height: 16),
    _sectionHeader('Dark Background'),
    _colorRow([const Color(0xFF121212), const Color(0xFF1a1a1a), const Color(0xFF212121), const Color(0xFF263238), const Color(0xFF1C1B1F)], _darkBg, (c) => setState(() => _darkBg = c)),
    const SizedBox(height: 16),
    _sectionHeader('Card Border Radius'),
    Row(children: [
      const Text('0'),
      Expanded(child: Slider.adaptive(value: _cardRadius, min: 0, max: 24, divisions: 12, label: _cardRadius.round().toString(), onChanged: (v) => setState(() => _cardRadius = v))),
      const Text('24'),
      const SizedBox(width: 8),
      Text('${_cardRadius.round()}px', style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
    const SizedBox(height: 24),
  ]);

  Widget _buildServiceTab() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('HTTP Headers (for authenticated file downloads)'),
    SwitchListTile.adaptive(title: const Text('Custom HTTP Headers'), subtitle: const Text('Attach Authorization / API key to file requests'), value: _enableCustomAuth, contentPadding: EdgeInsets.zero, onChanged: (v) => setState(() => _enableCustomAuth = v)),
    if (_enableCustomAuth) ...[
      const SizedBox(height: 8),
      TextFormField(controller: _apiKeyController, decoration: const InputDecoration(labelText: 'API Key / Bearer Token', border: OutlineInputBorder(), isDense: true, prefixIcon: Icon(Icons.key))),
    ],
    const SizedBox(height: 16),
    _sectionHeader('Available Server Sync Callbacks'),
    _callbackInfo('onBookmarksSync', 'Upload changed bookmarks to server'),
    _callbackInfo('onBookmarksLoad', 'Download bookmarks from server on init'),
    _callbackInfo('onAnnotationsSync', 'Upload drawing annotations'),
    _callbackInfo('onAnnotationsLoad', 'Download annotations on init'),
    _callbackInfo('onSessionStart', 'Called when user opens PDF'),
    _callbackInfo('onSessionEnd', 'Called with duration + current page on close'),
    _callbackInfo('onProgressSync', 'Called periodically with current page / total pages'),
    const SizedBox(height: 16),
    const Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Custom Storage', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Provide a PluginStorage implementation to use Hive, SharedPreferences, or any custom backend instead of the default GetStorage.', style: TextStyle(fontSize: 13)),
    ]))),
    const SizedBox(height: 24),
  ]);

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary, letterSpacing: 0.5)),
  );

  Widget _featureSwitch(String title, String subtitle, IconData icon, bool value, void Function(bool) onChanged) => SwitchListTile.adaptive(
    title: Row(children: [Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 14))]),
    subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
    value: value, dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    onChanged: onChanged,
  );

  Widget _colorRow(List<Color> colors, Color selected, void Function(Color) onSelected) => Wrap(spacing: 10, children: colors.map((c) {
    final isSelected = selected == c;
    return GestureDetector(
      onTap: () => onSelected(c),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: c,
          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400, width: isSelected ? 3 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isSelected ? Icon(Icons.check, color: ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : Colors.black, size: 18) : null,
      ),
    );
  }).toList());

  Widget _callbackInfo(String name, String description) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 4),
      Expanded(child: RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [
        TextSpan(text: '$name ', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 12)),
        TextSpan(text: '— $description', style: const TextStyle(fontSize: 12)),
      ]))),
    ]),
  );

  void _applyPreset(String preset) {
    setState(() {
      if (preset == 'all') {
        _enableBookmarks = _enableAnnotations = _enableSearch = _enableTextSelection =
        _enableThumbnails = _enableTOC = _enableAutoScroll = _enableDarkModeToggle =
        _enableFullscreen = _enablePageSlider = _enableKeepScreenOn =
        _enableSessionTracking = _enableScrollDirectionToggle = _enableSettings =
        _enableShare = true;
        _enableScreenProtection = false;
      } else if (preset == 'minimal') {
        _enableBookmarks = _enableAnnotations = _enableSearch = _enableTextSelection =
        _enableThumbnails = _enableTOC = _enableAutoScroll = _enableDarkModeToggle =
        _enableFullscreen = _enablePageSlider = _enableScreenProtection =
        _enableKeepScreenOn = _enableSessionTracking = _enableScrollDirectionToggle =
        _enableSettings = _enableShare = false;
      } else if (preset == 'readOnly') {
        _enableBookmarks = _enableAnnotations = _enableScreenProtection =
        _enableSessionTracking = _enableShare = false;
        _enableSearch = _enableTextSelection = _enableThumbnails = _enableTOC =
        _enableAutoScroll = _enableDarkModeToggle = _enableFullscreen =
        _enablePageSlider = _enableKeepScreenOn = _enableScrollDirectionToggle =
        _enableSettings = true;
      }
    });
  }

  PdfViewerThemeConfig _buildThemeConfig() => PdfViewerThemeConfig(
    primaryColor: _primaryColor,
    lightBackgroundColor: _lightBg,
    darkBackgroundColor: _darkBg,
    cardBorderRadius: _cardRadius,
    bookmarkColor: _primaryColor,
    sliderActiveColor: _primaryColor,
    loadingIndicatorColor: _primaryColor,
  );

  PdfViewerFeatureConfig _buildFeatureConfig() => PdfViewerFeatureConfig(
    enableBookmarks: _enableBookmarks,
    enableAnnotations: _enableAnnotations,
    enableSearch: _enableSearch,
    enableTextSelection: _enableTextSelection,
    enableThumbnails: _enableThumbnails,
    enableTableOfContents: _enableTOC,
    enableAutoScroll: _enableAutoScroll,
    enableDarkModeToggle: _enableDarkModeToggle,
    enableFullscreen: _enableFullscreen,
    enablePageSlider: _enablePageSlider,
    enableScreenProtection: _enableScreenProtection,
    enableKeepScreenOn: _enableKeepScreenOn,
    enableSessionTracking: _enableSessionTracking,
    enableScrollDirectionToggle: _enableScrollDirectionToggle,
    enableSettings: _enableSettings,
    enableShare: _enableShare,
  );

  PdfViewerServiceConfig _buildServiceConfig() => PdfViewerServiceConfig(
    onMessage: (message, type) {
      final color = type == ViewerMessageType.error ? Colors.red : type == ViewerMessageType.warning ? Colors.orange : Colors.green;
      Get.snackbar(type.name.toUpperCase(), message, snackPosition: SnackPosition.BOTTOM, backgroundColor: color.withValues(alpha: 0.9), colorText: Colors.white, duration: const Duration(seconds: 3));
    },
    httpHeaders: _enableCustomAuth ? {'Authorization': 'Bearer ${_apiKeyController.text}'} : null,
  );

  void _openFromFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      Get.to(() => PdfViewerScreen(
        filePath: result.files.single.path!, title: result.files.single.name.replaceAll('.pdf', ''),
        bookId: int.tryParse(_bookIdController.text),
        serviceConfig: _buildServiceConfig(), themeConfig: _buildThemeConfig(), featureConfig: _buildFeatureConfig(), externalDarkMode: widget.appDarkMode,
      ));
    }
  }

  void _openFromUrl() {
    Get.to(() => PdfViewerScreen(
      filePath: '', fileUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      title: 'Sample PDF from URL',
      serviceConfig: _buildServiceConfig(), themeConfig: _buildThemeConfig(), featureConfig: _buildFeatureConfig(), externalDarkMode: widget.appDarkMode,
    ));
  }

  void _openMinimal() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      Get.to(() => PdfViewerScreen(
        filePath: result.files.single.path!, title: result.files.single.name.replaceAll('.pdf', ''),
        featureConfig: PdfViewerFeatureConfig.minimal, externalDarkMode: widget.appDarkMode,
      ));
    }
  }

  void _openSimple() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      Get.to(() => SimplePdfViewer.file(
        result.files.single.path!,
      ));
    }
  }
}