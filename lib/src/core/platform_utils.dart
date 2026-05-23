import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Platform-adaptive icons for the PDF viewer.
/// Returns CupertinoIcons on iOS, Material Icons on other platforms.
class ViewerIcons {
  static IconData get back =>
      Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back;

  static IconData get close =>
      Platform.isIOS ? CupertinoIcons.xmark : Icons.close;

  static IconData get search =>
      Platform.isIOS ? CupertinoIcons.search : Icons.search;

  static IconData get bookmark =>
      Platform.isIOS ? CupertinoIcons.bookmark_fill : Icons.bookmark;

  static IconData get bookmarkOutline =>
      Platform.isIOS ? CupertinoIcons.bookmark : Icons.bookmark_border;

  static IconData get settings =>
      Platform.isIOS ? CupertinoIcons.settings : Icons.settings_outlined;

  static IconData get list =>
      Platform.isIOS ? CupertinoIcons.list_bullet : Icons.list;

  static IconData get copy =>
      Platform.isIOS ? CupertinoIcons.doc_on_doc : Icons.copy;

  static IconData get highlight =>
      Platform.isIOS ? CupertinoIcons.pencil_outline : Icons.highlight;

  static IconData get note =>
      Platform.isIOS ? CupertinoIcons.square_pencil : Icons.note_add;

  static IconData get delete =>
      Platform.isIOS ? CupertinoIcons.trash : Icons.delete_outline;

  static IconData get undo =>
      Platform.isIOS ? CupertinoIcons.arrow_uturn_left : Icons.undo;

  static IconData get redo =>
      Platform.isIOS ? CupertinoIcons.arrow_uturn_right : Icons.redo;

  static IconData get check =>
      Platform.isIOS ? CupertinoIcons.checkmark : Icons.check;

  static IconData get chevronLeft =>
      Platform.isIOS ? CupertinoIcons.chevron_left : Icons.chevron_left;

  static IconData get chevronRight =>
      Platform.isIOS ? CupertinoIcons.chevron_right : Icons.chevron_right;

  static IconData get fullscreenExit =>
      Platform.isIOS ? CupertinoIcons.fullscreen_exit : Icons.fullscreen_exit;

  static IconData get download =>
      Platform.isIOS ? CupertinoIcons.arrow_down_to_line : Icons.download;

  static IconData get error =>
      Platform.isIOS ? CupertinoIcons.exclamationmark_circle : Icons.error_outline;

  static IconData get refresh =>
      Platform.isIOS ? CupertinoIcons.refresh : Icons.refresh;

  static IconData get gridView =>
      Platform.isIOS ? CupertinoIcons.square_grid_2x2 : Icons.grid_view;

  static IconData get splitView =>
      Platform.isIOS ? CupertinoIcons.sidebar_left : Icons.view_column;

  static IconData get viewDayOutlined =>
      Platform.isIOS ? CupertinoIcons.doc_text : Icons.view_day_outlined;

  static IconData get fullscreen =>
      Platform.isIOS ? CupertinoIcons.fullscreen : Icons.fullscreen;

  static IconData get screenLock =>
      Platform.isIOS ? CupertinoIcons.lock_rotation : Icons.screen_lock_portrait;

  static IconData get sunOutlined =>
      Platform.isIOS ? CupertinoIcons.sun_min : Icons.wb_sunny_outlined;

  static IconData get darkMode =>
      Platform.isIOS ? CupertinoIcons.moon : Icons.dark_mode_outlined;

  static IconData get description =>
      Platform.isIOS ? CupertinoIcons.doc_text : Icons.description_outlined;

  // Additional icons used across the PDF viewer
  static IconData get checkCircle =>
      Platform.isIOS ? CupertinoIcons.checkmark_circle_fill : Icons.check_circle;

  static IconData get deleteSweep =>
      Platform.isIOS ? CupertinoIcons.trash : Icons.delete_sweep;

  static IconData get listAlt =>
      Platform.isIOS ? CupertinoIcons.list_bullet : Icons.list_alt_outlined;

  static IconData get editFilled =>
      Platform.isIOS ? CupertinoIcons.pencil : Icons.edit;

  static IconData get downloadFilled =>
      Platform.isIOS ? CupertinoIcons.arrow_down_to_line : Icons.download_rounded;

  static IconData get viewCarousel =>
      Platform.isIOS ? CupertinoIcons.rectangle_stack : Icons.view_carousel_rounded;

  static IconData get viewDay =>
      Platform.isIOS ? CupertinoIcons.doc_text : Icons.view_day_rounded;

  static IconData get arrowUp =>
      Platform.isIOS ? CupertinoIcons.chevron_up : Icons.keyboard_arrow_up;

  static IconData get arrowDown =>
      Platform.isIOS ? CupertinoIcons.chevron_down : Icons.keyboard_arrow_down;

  static IconData get searchOff =>
      Platform.isIOS ? CupertinoIcons.xmark_circle : Icons.search_off;

  static IconData get clearText =>
      Platform.isIOS ? CupertinoIcons.clear_circled_solid : Icons.clear;
}

/// Returns the appropriate keyboard brightness for iOS.
Brightness iosKeyboardBrightness(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Brightness.dark
      : Brightness.light;
}

/// Returns iOS BouncingScrollPhysics or Android ClampingScrollPhysics.
ScrollPhysics iosScrollPhysics() {
  return Platform.isIOS
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
  if (Platform.isIOS) {
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
