import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_chain/data/word_bank.dart';
import 'package:word_chain/main.dart';
import 'package:word_chain/models/app_settings.dart';
import 'package:word_chain/services/local_settings_store.dart';
import 'package:word_chain/services/local_stats_store.dart';

Future<void> pumpWordChain(WidgetTester tester, {AppSettings? settings}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final LocalSettingsStore settingsStore = LocalSettingsStore(preferences);

  if (settings != null) {
    await settingsStore.save(settings);
  }

  await tester.pumpWidget(
    WordChainApp(
      statsStore: LocalStatsStore(preferences),
      settingsStore: settingsStore,
    ),
  );
  await tester.pumpAndSettle();
}

String currentStartPhrase(WidgetTester tester) {
  for (final String phrase in WordBank.allPhrases()) {
    if (tester.any(find.text(phrase))) {
      return phrase;
    }
  }

  throw TestFailure('Could not find the start phrase.');
}

String validNextPhraseFor(String startPhrase) {
  final List<String> suggestions = WordBank.suggestionsFor(
    WordBank.lastWord(startPhrase),
    usedKeys: <String>{WordBank.phraseKey(startPhrase)},
    limit: 1,
  );

  if (suggestions.isEmpty) {
    throw TestFailure('Could not find a valid phrase after "$startPhrase".');
  }

  return suggestions.single;
}

void main() {
  testWidgets('game screen does not overflow on short screens', (
    WidgetTester tester,
  ) async {
    await pumpWordChain(tester);

    await tester.tap(find.text('Vô tận'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(390, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Lịch sử'), findsOneWidget);
  });

  testWidgets('home shows game modes', (WidgetTester tester) async {
    await pumpWordChain(tester);

    expect(find.text('Nối Từ'), findsOneWidget);
    expect(find.text('Vô tận'), findsOneWidget);
    expect(find.text('Tốc độ'), findsOneWidget);
    expect(find.text('Trí nhớ'), findsOneWidget);
    expect(find.text('2 người'), findsOneWidget);
  });

  testWidgets('two-player mode alternates turns after a valid phrase', (
    WidgetTester tester,
  ) async {
    await pumpWordChain(tester);

    await tester.tap(find.text('2 người'));
    await tester.pumpAndSettle();

    expect(find.text('Lượt: Người 1'), findsOneWidget);

    final String startPhrase = currentStartPhrase(tester);
    final String validPhrase = validNextPhraseFor(startPhrase);

    await tester.enterText(find.byType(EditableText), validPhrase);
    await tester.tap(find.text('Gửi'));
    await tester.pump();

    expect(find.text('Lượt: Người 2'), findsOneWidget);
    expect(find.text(validPhrase), findsWidgets);
  });

  testWidgets('settings screen shows answer time language and theme controls', (
    WidgetTester tester,
  ) async {
    await pumpWordChain(tester);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Thời gian trả lời'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsWidgets);
    expect(find.text('Giao diện'), findsOneWidget);
    expect(find.text('Hệ thống'), findsOneWidget);
  });

  testWidgets('configured answer time is used in a new game', (
    WidgetTester tester,
  ) async {
    await pumpWordChain(
      tester,
      settings: AppSettings.defaults().copyWith(answerSeconds: 12),
    );

    await tester.tap(find.text('Vô tận'));
    await tester.pumpAndSettle();

    expect(find.text('12s'), findsOneWidget);
  });

  testWidgets('endless mode accepts a valid chained phrase', (
    WidgetTester tester,
  ) async {
    await pumpWordChain(tester);

    await tester.tap(find.text('Vô tận'));
    await tester.pumpAndSettle();

    final String startPhrase = currentStartPhrase(tester);
    final String validPhrase = validNextPhraseFor(startPhrase);

    await tester.enterText(find.byType(EditableText), validPhrase);
    await tester.tap(find.text('Gửi'));
    await tester.pump();

    expect(find.textContaining('Đúng'), findsOneWidget);
    expect(find.text(validPhrase), findsWidgets);
  });

  testWidgets('game rejects English words', (WidgetTester tester) async {
    await pumpWordChain(tester);

    await tester.tap(find.text('Vô tận'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'Đá internet');
    await tester.tap(find.text('Gửi'));
    await tester.pump();

    expect(find.textContaining('Chỉ dùng từ tiếng Việt'), findsOneWidget);
  });
}
