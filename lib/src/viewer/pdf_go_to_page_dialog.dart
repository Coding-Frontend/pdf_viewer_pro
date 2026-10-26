import 'package:flutter/material.dart';

import '../core/platform_utils.dart';

/// Shared by the URL/data and file-path reader screens.
Future<void> showPdfGoToPageDialog({
  required BuildContext context,
  required int totalPages,
  required bool isDark,
  required ValueChanged<int> onGoToPage,
}) {
  final textColor = isDark ? Colors.white : Colors.black87;
  final formKey = GlobalKey<FormState>();

  void submit() {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();
    Navigator.of(formKey.currentContext!).pop();
  }

  // Cupertino dialogs do not supply a Material ancestor for the input/actions.
  Widget materialChild(Widget child) =>
      Material(type: MaterialType.transparency, child: child);

  return showViewerDialog<void>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF2a2a2a) : Colors.white,
    title: 'Go to Page',
    content: materialChild(
      Form(
        key: formKey,
        child: TextFormField(
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofocus: true,
          keyboardAppearance: iosKeyboardBrightness(context),
          style: TextStyle(color: textColor),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            labelText: 'Page',
            labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
            hintText: '1–$totalPages',
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          errorBuilder: (context, message) => Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Enter a page number.';
            final page = int.tryParse(text);
            if (page == null) return 'Enter a whole page number.';
            if (page < 1 || page > totalPages) {
              return 'Enter a page from 1 to $totalPages.';
            }
            return null;
          },
          onSaved: (value) => onGoToPage(int.parse(value!.trim())),
          onFieldSubmitted: (_) => submit(),
        ),
      ),
    ),
    actions: [
      materialChild(
        TextButton(
          onPressed: () => Navigator.of(formKey.currentContext!).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: textColor.withValues(alpha: 0.6)),
          ),
        ),
      ),
      materialChild(
        TextButton(
          onPressed: submit,
          child: Text(
            'Go',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    ],
  );
}
