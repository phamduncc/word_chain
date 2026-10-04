import 'dart:convert';

import 'package:flutter/material.dart';

import 'game_models.dart';

enum AppLanguage { vietnamese, english }

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceInfo on AppThemePreference {
  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }
}

class AppSettings {
  const AppSettings({
    required this.answerSeconds,
    required this.language,
    required this.themePreference,
  });

  final int answerSeconds;
  final AppLanguage language;
  final AppThemePreference themePreference;

  factory AppSettings.defaults() {
    return const AppSettings(
      answerSeconds: 10,
      language: AppLanguage.vietnamese,
      themePreference: AppThemePreference.system,
    );
  }

  factory AppSettings.fromStoredJson(String? source) {
    if (source == null || source.isEmpty) {
      return AppSettings.defaults();
    }

    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return AppSettings.defaults();
      }

      return AppSettings(
        answerSeconds: _clampAnswerSeconds(
          _readInt(decoded['answerSeconds'], fallback: 10),
        ),
        language: AppLanguage.values.byName(
          decoded['language'] as String? ?? AppLanguage.vietnamese.name,
        ),
        themePreference: AppThemePreference.values.byName(
          decoded['themePreference'] as String? ??
              AppThemePreference.system.name,
        ),
      );
    } on ArgumentError {
      return AppSettings.defaults();
    } on FormatException {
      return AppSettings.defaults();
    } on TypeError {
      return AppSettings.defaults();
    }
  }

  AppSettings copyWith({
    int? answerSeconds,
    AppLanguage? language,
    AppThemePreference? themePreference,
  }) {
    return AppSettings(
      answerSeconds: _clampAnswerSeconds(answerSeconds ?? this.answerSeconds),
      language: language ?? this.language,
      themePreference: themePreference ?? this.themePreference,
    );
  }

  String toStoredJson() {
    return jsonEncode(<String, dynamic>{
      'answerSeconds': answerSeconds,
      'language': language.name,
      'themePreference': themePreference.name,
    });
  }

  static int _readInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? fallback;
  }

  static int _clampAnswerSeconds(int value) {
    return value.clamp(5, 30).toInt();
  }
}

class AppCopy {
  const AppCopy._(this.language);

  final AppLanguage language;

  bool get isEnglish => language == AppLanguage.english;

  static AppCopy of(AppLanguage language) => AppCopy._(language);

  String get appName => isEnglish ? 'Word Chain' : 'Nối Từ';
  String get smartTitle => isEnglish ? 'Smart Word Chain' : 'Nối Từ Thông Minh';
  String get settings => isEnglish ? 'Settings' : 'Cài đặt';
  String get statistics => isEnglish ? 'Statistics' : 'Thống kê';
  String get difficulty => isEnglish ? 'Difficulty' : 'Độ khó';
  String get theme => isEnglish ? 'Topic' : 'Chủ đề';
  String get endless => isEnglish ? 'Endless' : 'Vô tận';
  String get speed => isEnglish ? 'Speed' : 'Tốc độ';
  String get memory => isEnglish ? 'Memory' : 'Trí nhớ';
  String get daily => isEnglish ? 'Daily' : 'Hằng ngày';
  String get bigChallenge => isEnglish ? 'Big challenge' : 'Thử thách lớn';
  String get twoPlayers => isEnglish ? '2 players' : '2 người';
  String get records => isEnglish ? 'Records' : 'Kỷ lục';
  String get day => isEnglish ? 'Day' : 'Ngày';
  String get fast => isEnglish ? 'Fast' : 'Nhanh';
  String get trophies => isEnglish ? 'Trophies' : 'Cúp';
  String get currentPhrase => isEnglish ? 'Current phrase' : 'Từ hiện tại';
  String get newPhrase => isEnglish ? 'New phrase' : 'Từ mới';
  String get send => isEnglish ? 'Send' : 'Gửi';
  String get hint => isEnglish ? 'Hint' : 'Gợi ý';
  String get history => isEnglish ? 'History' : 'Lịch sử';
  String get turn => isEnglish ? 'Turn' : 'Lượt';
  String get total => isEnglish ? 'Total' : 'Tổng';
  String get score => isEnglish ? 'Score' : 'Điểm';
  String get chain => isEnglish ? 'Chain' : 'Chuỗi';
  String get streak => isEnglish ? 'Streak' : 'Liên tiếp';
  String get finish => isEnglish ? 'Finish' : 'Kết thúc';
  String get gameOver => isEnglish ? 'Game over' : 'Kết thúc';
  String get victory => isEnglish ? 'Victory' : 'Chiến thắng';
  String get playAgain => isEnglish ? 'Play again' : 'Chơi lại';
  String get home => isEnglish ? 'Home' : 'Trang chủ';
  String get answer => isEnglish ? 'Answer' : 'Câu trả lời';
  String get reply => isEnglish ? 'Reply' : 'Trả lời';
  String get memoryCheck => isEnglish ? 'Memory check' : 'Thử trí nhớ';
  String get hiddenChain =>
      isEnglish ? 'Chain is hidden' : 'Chuỗi đang được ẩn';
  String get checkingMemory =>
      isEnglish ? 'Checking memory.' : 'Đang kiểm tra trí nhớ.';
  String get memoryCheckingTitle =>
      isEnglish ? 'Memory check in progress' : 'Đang kiểm tra trí nhớ';
  String get wrongMemory =>
      isEnglish ? 'Wrong memory answer' : 'Sai câu hỏi trí nhớ';
  String get memoryCorrect =>
      isEnglish ? 'Memory correct. +25 points' : 'Trí nhớ chính xác. +25 điểm';
  String get emptyInput =>
      isEnglish ? 'Input cannot be empty.' : 'Không được bỏ trống.';
  String get repeatedPhrase =>
      isEnglish ? 'This phrase was already used.' : 'Cụm từ này đã được dùng.';
  String get hardNoHints => isEnglish
      ? 'Hard difficulty has no hints.'
      : 'Độ khó Khó không có gợi ý.';
  String get noHints =>
      isEnglish ? 'No matching hints yet.' : 'Chưa có gợi ý phù hợp.';
  String get endedByUser =>
      isEnglish ? 'You ended the run' : 'Bạn kết thúc lượt';
  String get timeOutTurn =>
      isEnglish ? 'Turn time is up' : 'Hết thời gian lượt';
  String get timeOutRun => isEnglish ? '60 seconds are up' : 'Hết 60 giây';
  String get challengeComplete =>
      isEnglish ? 'Challenge complete' : 'Hoàn thành thử thách';
  String get newAchievement => isEnglish ? 'New achievement' : 'Thành tích mới';
  String get correctWords => isEnglish ? 'Correct words' : 'Từ đúng';
  String get fastest => isEnglish ? 'Fastest' : 'Nhanh nhất';
  String get speedScore => isEnglish ? 'Speed score' : 'Điểm tốc độ';
  String get hintsUsed => isEnglish ? 'Hints used' : 'Gợi ý đã dùng';
  String get bigChallengeWins =>
      isEnglish ? 'Big challenge wins' : 'Thắng thử thách lớn';
  String get achievements => isEnglish ? 'Achievements' : 'Thành tích';
  String get answerTime => isEnglish ? 'Answer time' : 'Thời gian trả lời';
  String get languageLabel => isEnglish ? 'Language' : 'Ngôn ngữ';
  String get appTheme => isEnglish ? 'App theme' : 'Giao diện';
  String get systemTheme => isEnglish ? 'System' : 'Hệ thống';
  String get lightTheme => isEnglish ? 'Light' : 'Sáng';
  String get darkTheme => isEnglish ? 'Dark' : 'Tối';
  String get vietnamese => isEnglish ? 'Vietnamese' : 'Tiếng Việt';
  String get english => isEnglish ? 'English' : 'Tiếng Anh';

  String modeTitle(GameMode mode) {
    switch (mode) {
      case GameMode.endless:
        return endless;
      case GameMode.speed:
        return speed;
      case GameMode.memory:
        return memory;
      case GameMode.theme:
        return theme;
      case GameMode.daily:
        return isEnglish ? 'Daily challenge' : 'Thử thách ngày';
      case GameMode.boss:
        return bigChallenge;
      case GameMode.twoPlayer:
        return twoPlayers;
    }
  }

  String player(int index) {
    return isEnglish ? 'Player $index' : 'Người $index';
  }

  String currentPlayer(int index) {
    return isEnglish ? 'Turn: Player $index' : 'Lượt: Người $index';
  }

  String winner(int index) {
    return isEnglish ? 'Winner: Player $index' : 'Thắng: Người $index';
  }

  String get draw => isEnglish ? 'Draw' : 'Hòa';

  String startsWith(String word) {
    return isEnglish ? 'Starts with: "$word"' : 'Bắt đầu bằng: "$word"';
  }

  String mustStartWith(String word) {
    return isEnglish
        ? 'The new phrase must start with "$word".'
        : 'Từ mới phải bắt đầu bằng "$word".';
  }

  String correctPhrase(String phrase) {
    return isEnglish ? 'Correct: $phrase' : 'Đúng: $phrase';
  }

  String hintFor(String word) {
    return isEnglish ? 'Hint for "$word".' : 'Gợi ý cho "$word".';
  }

  String onlyVietnamese(String token) {
    return isEnglish
        ? 'Only Vietnamese words are allowed. "$token" is invalid.'
        : 'Chỉ dùng từ tiếng Việt. "$token" không hợp lệ.';
  }

  String memoryPhraseQuestion(int index) {
    return isEnglish ? 'What is phrase number $index?' : 'Từ thứ $index là gì?';
  }

  String get memoryLengthQuestion {
    return isEnglish
        ? 'How long is the current chain?'
        : 'Chuỗi hiện tại dài bao nhiêu?';
  }

  String seconds(int value) {
    return isEnglish ? '$value seconds' : '$value giây';
  }
}
