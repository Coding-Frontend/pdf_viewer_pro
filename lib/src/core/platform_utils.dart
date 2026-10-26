import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Native-only platform decisions. A browser on iOS still uses the web path.
class ViewerPlatform {
  static bool isNative(
    TargetPlatform platform, {
    bool isWeb = kIsWeb,
    TargetPlatform? targetPlatform,
  }) =>
      !isWeb && (targetPlatform ?? defaultTargetPlatform) == platform;

  static bool get isIOS => isNative(TargetPlatform.iOS);
  static bool get isAndroid => isNative(TargetPlatform.android);
}

/// Platform-adaptive icons for the PDF viewer.
/// Returns CupertinoIcons on iOS, Material Icons on other platforms.
class ViewerIcons {
  static IconData get back =>
      ViewerPlatform.isIOS ? CupertinoIcons.back : Icons.arrow_back;

  static IconData get close =>
      ViewerPlatform.isIOS ? CupertinoIcons.xmark : Icons.close;

  static IconData get search =>
      ViewerPlatform.isIOS ? CupertinoIcons.search : Icons.search;

  static IconData get bookmark =>
      ViewerPlatform.isIOS ? CupertinoIcons.bookmark_fill : Icons.bookmark;

  static IconData get bookmarkOutline =>
      ViewerPlatform.isIOS ? CupertinoIcons.bookmark : Icons.bookmark_border;

  static IconData get settings =>
      ViewerPlatform.isIOS ? CupertinoIcons.settings : Icons.settings_outlined;

  static IconData get list =>
      ViewerPlatform.isIOS ? CupertinoIcons.list_bullet : Icons.list;

  static IconData get copy =>
      ViewerPlatform.isIOS ? CupertinoIcons.doc_on_doc : Icons.copy;

  static IconData get highlight =>
      ViewerPlatform.isIOS ? CupertinoIcons.pencil_outline : Icons.highlight;

  static IconData get note =>
      ViewerPlatform.isIOS ? CupertinoIcons.square_pencil : Icons.note_add;

  static IconData get delete =>
      ViewerPlatform.isIOS ? CupertinoIcons.trash : Icons.delete_outline;

  static IconData get undo =>
      ViewerPlatform.isIOS ? CupertinoIcons.arrow_uturn_left : Icons.undo;

  static IconData get redo =>
      ViewerPlatform.isIOS ? CupertinoIcons.arrow_uturn_right : Icons.redo;

  static IconData get check =>
      ViewerPlatform.isIOS ? CupertinoIcons.checkmark : Icons.check;

  static IconData get chevronLeft =>
      ViewerPlatform.isIOS ? CupertinoIcons.chevron_left : Icons.chevron_left;

  static IconData get chevronRight =>
      ViewerPlatform.isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right;

  static IconData get fullscreenExit => ViewerPlatform.isIOS
      ? CupertinoIcons.fullscreen_exit
      : Icons.fullscreen_exit;

  static IconData get download =>
      ViewerPlatform.isIOS ? CupertinoIcons.arrow_down_to_line : Icons.download;

  static IconData get error => ViewerPlatform.isIOS
      ? CupertinoIcons.exclamationmark_circle
      : Icons.error_outline;

  static IconData get refresh =>
      ViewerPlatform.isIOS ? CupertinoIcons.refresh : Icons.refresh;

  static IconData get gridView =>
      ViewerPlatform.isIOS ? CupertinoIcons.square_grid_2x2 : Icons.grid_view;

  static IconData get splitView =>
      ViewerPlatform.isIOS ? CupertinoIcons.sidebar_left : Icons.view_column;

  static IconData get viewDayOutlined =>
      ViewerPlatform.isIOS ? CupertinoIcons.doc_text : Icons.view_day_outlined;

  static IconData get fullscreen =>
      ViewerPlatform.isIOS ? CupertinoIcons.fullscreen : Icons.fullscreen;

  static IconData get screenLock => ViewerPlatform.isIOS
      ? CupertinoIcons.lock_rotation
      : Icons.screen_lock_portrait;

  static IconData get sunOutlined =>
      ViewerPlatform.isIOS ? CupertinoIcons.sun_min : Icons.wb_sunny_outlined;

  static IconData get darkMode =>
      ViewerPlatform.isIOS ? CupertinoIcons.moon : Icons.dark_mode_outlined;

  static IconData get description => ViewerPlatform.isIOS
      ? CupertinoIcons.doc_text
      : Icons.description_outlined;

  // Additional icons used across the PDF viewer
  static IconData get checkCircle => ViewerPlatform.isIOS
      ? CupertinoIcons.checkmark_circle_fill
      : Icons.check_circle;

  static IconData get deleteSweep =>
      ViewerPlatform.isIOS ? CupertinoIcons.trash : Icons.delete_sweep;

  static IconData get listAlt => ViewerPlatform.isIOS
      ? CupertinoIcons.list_bullet
      : Icons.list_alt_outlined;

  static IconData get editFilled =>
      ViewerPlatform.isIOS ? CupertinoIcons.pencil : Icons.edit;

  static IconData get downloadFilled => ViewerPlatform.isIOS
      ? CupertinoIcons.arrow_down_to_line
      : Icons.download_rounded;

  static IconData get viewCarousel => ViewerPlatform.isIOS
      ? CupertinoIcons.rectangle_stack
      : Icons.view_carousel_rounded;

  static IconData get viewDay =>
      ViewerPlatform.isIOS ? CupertinoIcons.doc_text : Icons.view_day_rounded;

  static IconData get arrowUp => ViewerPlatform.isIOS
      ? CupertinoIcons.chevron_up
      : Icons.keyboard_arrow_up;

  static IconData get arrowDown => ViewerPlatform.isIOS
      ? CupertinoIcons.chevron_down
      : Icons.keyboard_arrow_down;

  static IconData get searchOff =>
      ViewerPlatform.isIOS ? CupertinoIcons.xmark_circle : Icons.search_off;

  static IconData get clearText =>
      ViewerPlatform.isIOS ? CupertinoIcons.clear_circled_solid : Icons.clear;
}

/// Returns the appropriate keyboard brightness for iOS.
Brightness iosKeyboardBrightness(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Brightness.dark
      : Brightness.light;
}

/// Returns iOS BouncingScrollPhysics or Android ClampingScrollPhysics.
ScrollPhysics iosScrollPhysics() {
  return ViewerPlatform.isIOS
      ? const BouncingScrollPhysics()
      : const ClampingScrollPhysics();
}

/// Shows an iOS-adaptive dialog.
/// On iOS shows a CupertinoAlertDialog; on others shows a standard AlertDialog.
Future<T?> showViewerDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
  Color? backgroundColor,
}) {
  if (ViewerPlatform.isIOS) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: content,
      actions: actions,
    ),
  );
}
