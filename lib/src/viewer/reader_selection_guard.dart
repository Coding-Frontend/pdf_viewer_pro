import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef ReaderSelectionMenuBuilder = Widget Function(
  BuildContext context,
  SelectableRegionState state,
);

/// Keeps text selectable while suppressing the secondary-click menu.
///
/// Long-press selection still uses the reader's normal toolbar. This is a
/// Flutter-side guard for desktop/native pointer events; browser-level page
/// menus must additionally be disabled by the host web shell if the app is
/// ever compiled for web.
class ReaderSelectionGuard extends StatefulWidget {
  final Widget child;
  final ReaderSelectionMenuBuilder? menuBuilder;

  const ReaderSelectionGuard({
    super.key,
    required this.child,
    this.menuBuilder,
  });

  @override
  State<ReaderSelectionGuard> createState() => _ReaderSelectionGuardState();
}

class _ReaderSelectionGuardState extends State<ReaderSelectionGuard> {
  Timer? _resetTimer;
  bool _suppressNextContextMenu = false;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons & kSecondaryMouseButton != 0) {
      _resetTimer?.cancel();
      _suppressNextContextMenu = true;
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (!_suppressNextContextMenu) return;
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 250), () {
      _suppressNextContextMenu = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: SelectionArea(
        contextMenuBuilder: (context, state) {
          if (_suppressNextContextMenu) {
            _suppressNextContextMenu = false;
            _resetTimer?.cancel();
            return const SizedBox.shrink();
          }
          return widget.menuBuilder?.call(context, state) ??
              AdaptiveTextSelectionToolbar.buttonItems(
                anchors: state.contextMenuAnchors,
                buttonItems: state.contextMenuButtonItems,
              );
        },
        child: widget.child,
      ),
    );
  }
}
