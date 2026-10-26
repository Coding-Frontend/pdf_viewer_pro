import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_viewer_pro/src/viewer/pdf_go_to_page_dialog.dart';

Future<void> _openDialog(
  WidgetTester tester,
  List<int> dispatched, {
  int totalPages = 2,
  bool isDark = false,
  double textScale = 1,
  bool supportsAnnounce = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: isDark ? Brightness.dark : Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(
          textScaler: TextScaler.linear(textScale),
          supportsAnnounce: supportsAnnounce,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showPdfGoToPageDialog(
                context: context,
                totalPages: totalPages,
                isDark: isDark,
                onGoToPage: (page) {
                  // Preserve dispatch-before-dismiss behavior.
                  expect(find.text('Go to Page'), findsOneWidget);
                  dispatched.add(page);
                },
              ),
              child: const Text('Open reader dialog'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open reader dialog'));
  await tester.pumpAndSettle();
}

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    final variant = TargetPlatformVariant.only(platform);

    testWidgets(
      'invalid pages stay open with accessible feedback on $platform',
      (tester) async {
        final dispatched = <int>[];
        await _openDialog(tester, dispatched);

        expect(
          find.byType(CupertinoAlertDialog),
          platform == TargetPlatform.iOS ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(AlertDialog),
          platform == TargetPlatform.iOS ? findsNothing : findsOneWidget,
        );
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.decoration!.labelText, 'Page');
        expect(field.decoration!.hintText, '1–2');
        expect(field.keyboardType, TextInputType.number);

        const invalid = {
          '': 'Enter a page number.',
          '   ': 'Enter a page number.',
          'NaN': 'Enter a whole page number.',
          'chapter': 'Enter a whole page number.',
          '1.5': 'Enter a whole page number.',
          '0': 'Enter a page from 1 to 2.',
          '-1': 'Enter a page from 1 to 2.',
          '3': 'Enter a page from 1 to 2.',
          '99': 'Enter a page from 1 to 2.',
        };
        for (final entry in invalid.entries) {
          await tester.enterText(find.byType(TextFormField), entry.key);
          await tester.tap(find.text('Go'));
          await tester.pumpAndSettle();

          expect(find.text(entry.value), findsOneWidget, reason: entry.key);
          expect(
            tester.getSemantics(find.text(entry.value)),
            matchesSemantics(label: entry.value, isLiveRegion: true),
          );
          expect(find.text('Go to Page'), findsOneWidget);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            entry.key,
          );
          expect(dispatched, isEmpty);
          expect(tester.takeException(), isNull);
        }

        await tester.enterText(find.byType(TextFormField), ' 2 ');
        await tester.pumpAndSettle();
        expect(find.text('Enter a page from 1 to 2.'), findsNothing);
        await tester.tap(find.text('Go'));
        await tester.pumpAndSettle();
        expect(dispatched, [2]);
        expect(find.text('Go to Page'), findsNothing);
        expect(find.text('Open reader dialog'), findsOneWidget);
      },
      variant: variant,
    );

    testWidgets(
      'keyboard submission validates and dispatches on $platform',
      (tester) async {
        final dispatched = <int>[];
        await _openDialog(tester, dispatched);
        for (final input in ['', 'NaN', '99']) {
          await tester.enterText(find.byType(TextFormField), input);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(find.text('Go to Page'), findsOneWidget);
          expect(dispatched, isEmpty);
          expect(
              find.text(input.isEmpty
                  ? 'Enter a page number.'
                  : input == 'NaN'
                      ? 'Enter a whole page number.'
                      : 'Enter a page from 1 to 2.'),
              findsOneWidget);
        }
        await tester.enterText(find.byType(TextFormField), '1');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(dispatched, [1]);
        expect(find.text('Go to Page'), findsNothing);
        expect(tester.takeException(), isNull);
      },
      variant: variant,
    );

    testWidgets('validation announces errors when supported on $platform',
        (tester) async {
      final messages = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler(
        SystemChannels.accessibility,
        (message) async {
          messages.add(message);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler(SystemChannels.accessibility, null));
      final dispatched = <int>[];
      await _openDialog(tester, dispatched, supportsAnnounce: true);
      await tester.enterText(find.byType(TextFormField), '99');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      // Flutter delays iOS form announcements by one second.
      await tester.pump(const Duration(seconds: 2));
      expect(
        messages,
        contains(predicate<Object?>((message) =>
            message is Map &&
            message['type'] == 'announce' &&
            (message['data'] as Map)['message'] ==
                'Enter a page from 1 to 2.')),
      );
      expect(dispatched, isEmpty);
      expect(find.text('Go to Page'), findsOneWidget);
    }, variant: variant);

    testWidgets('cancel after invalid input never dispatches on $platform', (
      tester,
    ) async {
      final dispatched = <int>[];
      await _openDialog(tester, dispatched);
      await tester.enterText(find.byType(TextFormField), '99');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Go to Page'), findsNothing);
      expect(find.text('Open reader dialog'), findsOneWidget);
      expect(dispatched, isEmpty);

      await tester.tap(find.text('Open reader dialog'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Enter a page from 1 to 2.'), findsNothing);
    }, variant: variant);

    testWidgets('range follows the actual document on $platform', (
      tester,
    ) async {
      final dispatched = <int>[];
      await _openDialog(tester, dispatched, totalPages: 237);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        '1–237',
      );
      await tester.enterText(find.byType(TextFormField), '238');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a page from 1 to 237.'), findsOneWidget);
      expect(dispatched, isEmpty);
      await tester.enterText(find.byType(TextFormField), '237');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(dispatched, [237]);
      expect(find.text('Go to Page'), findsNothing);
    }, variant: variant);

    for (final width in [390.0, 320.0]) {
      testWidgets('range and errors fit a ${width}px phone on $platform', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.reset);
        final dispatched = <int>[];
        await _openDialog(
          tester,
          dispatched,
          isDark: true,
          textScale: width == 320 ? 2 : 1,
        );

        void expectTextFits(String text) {
          final richText = find.descendant(
            of: find.text(text),
            matching: find.byType(RichText),
          );
          final paragraph = tester.renderObject<RenderParagraph>(richText);
          expect(paragraph.didExceedMaxLines, isFalse, reason: text);
          final rect = tester.getRect(find.text(text));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
        }

        expectTextFits('1–2');
        expectTextFits('Page');
        for (final entry in {
          '': 'Enter a page number.',
          'NaN': 'Enter a whole page number.',
          '99': 'Enter a page from 1 to 2.',
        }.entries) {
          await tester.enterText(find.byType(TextFormField), entry.key);
          await tester.tap(find.text('Go'));
          await tester.pumpAndSettle();
          expectTextFits(entry.value);
        }
        expect(tester.getRect(find.text('Go')).bottom, lessThanOrEqualTo(544));
        expect(dispatched, isEmpty);
        expect(tester.takeException(), isNull);
      }, variant: variant);
    }
  }
}
