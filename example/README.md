# pdf_viewer_pro_example

Example application for `pdf_viewer_pro`.

## Capture Real Screenshots

The example includes an integration test that can capture real screenshots on a connected device or emulator.

1. Open a terminal and change to the example folder:

```bash
cd pdf_viewer_pro/example
flutter pub get
```

2. Start an emulator or connect a device.

3. Run the integration test (driver mode) to capture screenshots:

```bash
flutter drive --driver=integration_test/driver.dart --target=integration_test/screenshot_test.dart -d <deviceId>
```

Replace `<deviceId>` with your emulator/device id (use `flutter devices` to list devices).

The test will open the example app, tap the "Open from URL" button to load a sample PDF, and capture screenshots (home, reader, thumbnails). Check the test output logs for generated screenshot paths.
