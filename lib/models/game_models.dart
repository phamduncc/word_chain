import 'dart:convert';

enum GameMode { endless, speed, memory, theme, daily, boss, twoPlayer }

enum GameDifficulty { easy, medium, hard }

extension GameDifficultyInfo on GameDifficulty {
  String get label {
    switch (this) {
      case GameDifficulty.easy:
        return 'Dễ';
      case GameDifficulty.medium:
        return 'Trung bình';
      case GameDifficulty.hard:
        return 'Khó';
    }
  }

  int get turnSeconds {
    switch (this) {
      case GameDifficulty.easy:
        return 15;
      case GameDifficulty.medium:
        return 10;
      case GameDifficulty.hard:
        return 5;
    }
  }

  bool get allowsHints => this != GameDifficulty.hard;

  bool get hasFreeHints => this == GameDifficulty.easy;
}

enum ChainTheme { sports, geography, technology, entertainment, study }

extension ChainThemeInfo on ChainTheme {
  String get label {
    switch (this) {
      case ChainTheme.sports:
        return 'Thể thao';
      case ChainTheme.geography:
        return 'Địa lý';
      case ChainTheme.technology:
        return 'Công nghệ';
      case ChainTheme.entertainment:
        return 'Giải trí';
      case ChainTheme.study:
        return 'Học tập';
    }
  }
}

class WordChain {
  const WordChain({required this.phrase, required this.createdAt});

  final String phrase;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'phrase': phrase,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WordChain.fromJson(Map<String, dynamic> json) {
    return WordChain(
      phrase: json['phrase'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class GameConfig {
  const GameConfig({
    required this.mode,
    required this.difficulty,
    this.turnSeconds,
    this.theme,
    this.totalSeconds,
    this.targetCorrectWords,
  });

  final GameMode mode;
  final GameDifficulty difficulty;
  final int? turnSeconds;
  final ChainTheme? theme;
  final int? totalSeconds;
  final int? targetCorrectWords;

  bool get isTimedRun => totalSeconds != null;
  bool get usesMemoryQuiz => mode == GameMode.memory;
  int get effectiveTurnSeconds => turnSeconds ?? difficulty.turnSeconds;

  String get title {
    switch (mode) {
      case GameMode.endless:
        return 'Vô tận';
      case GameMode.speed:
        return 'Tốc độ';
      case GameMode.memory:
        return 'Trí nhớ';
      case GameMode.theme:
        return 'Chủ đề';
      case GameMode.daily:
        return 'Thử thách ngày';
      case GameMode.boss:
        return 'Thử thách lớn';
      case GameMode.twoPlayer:
        return '2 người';
    }
  }
}

class GameResult {
  const GameResult({
    required this.mode,
    required this.chainLength,
    required this.correctWords,
    required this.score,
    required this.hintsUsed,
    required this.fastestAnswerMs,
    this.theme,
    this.completedBoss = false,
    this.dailyKey,
  });

  final GameMode mode;
  final int chainLength;
  final int correctWords;
  final int score;
  final int hintsUsed;
  final int fastestAnswerMs;
  final ChainTheme? theme;
  final bool completedBoss;
  final String? dailyKey;
}

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

const List<AchievementDefinition> achievementDefinitions =
    <AchievementDefinition>[
      AchievementDefinition(
        id: 'chain_10',
        title: 'Chuỗi 10 từ',
        subtitle: 'Đạt chuỗi dài ít nhất 10 cụm từ.',
      ),
      AchievementDefinition(
        id: 'chain_50',
        title: 'Chuỗi 50 từ',
        subtitle: 'Đạt chuỗi dài ít nhất 50 cụm từ.',
      ),
      AchievementDefinition(
        id: 'no_hint',
        title: 'Không dùng gợi ý',
        subtitle: 'Hoàn thành ít nhất 5 lượt nối không dùng gợi ý.',
      ),
      AchievementDefinition(
        id: 'under_3_seconds',
        title: 'Tốc độ dưới 3 giây',
        subtitle: 'Có một lượt trả lời trong 3 giây.',
      ),
      AchievementDefinition(
        id: 'sports_expert',
        title: 'Chuyên gia Thể thao',
        subtitle: 'Đạt chuỗi 10 từ trong chủ đề Thể thao.',
      ),
      AchievementDefinition(
        id: 'boss_badge',
        title: 'Chinh phục Mạng lưới',
        subtitle: 'Nối 20 từ trong 60 giây ở thử thách lớn.',
      ),
    ];

class PlayerStats {
  PlayerStats({
    required this.bestEndlessChain,
    required this.bestSpeedScore,
    required this.bestSpeedWords,
    required this.bestMemoryChain,
    required this.bestThemeChain,
    required this.totalValidWords,
    required this.totalHintsUsed,
    required this.fastestAnswerMs,
    required this.dailyBestDate,
    required this.dailyBestChain,
    required this.bossWins,
    required this.achievements,
    required this.bestThemeChains,
  });

  int bestEndlessChain;
  int bestSpeedScore;
  int bestSpeedWords;
  int bestMemoryChain;
  int bestThemeChain;
  int totalValidWords;
  int totalHintsUsed;
  int fastestAnswerMs;
  String dailyBestDate;
  int dailyBestChain;
  int bossWins;
  Set<String> achievements;
  Map<String, int> bestThemeChains;

  factory PlayerStats.empty() {
    return PlayerStats(
      bestEndlessChain: 0,
      bestSpeedScore: 0,
      bestSpeedWords: 0,
      bestMemoryChain: 0,
      bestThemeChain: 0,
      totalValidWords: 0,
      totalHintsUsed: 0,
      fastestAnswerMs: 0,
      dailyBestDate: '',
      dailyBestChain: 0,
      bossWins: 0,
      achievements: <String>{},
      bestThemeChains: <String, int>{},
    );
  }

  factory PlayerStats.fromStoredJson(String? source) {
    if (source == null || source.isEmpty) {
      return PlayerStats.empty();
    }

    try {
      final Object? decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        return PlayerStats.empty();
      }

      return PlayerStats(
        bestEndlessChain: _readInt(decoded['bestEndlessChain']),
        bestSpeedScore: _readInt(decoded['bestSpeedScore']),
        bestSpeedWords: _readInt(decoded['bestSpeedWords']),
        bestMemoryChain: _readInt(decoded['bestMemoryChain']),
        bestThemeChain: _readInt(decoded['bestThemeChain']),
        totalValidWords: _readInt(decoded['totalValidWords']),
        totalHintsUsed: _readInt(decoded['totalHintsUsed']),
        fastestAnswerMs: _readInt(decoded['fastestAnswerMs']),
        dailyBestDate: decoded['dailyBestDate'] as String? ?? '',
        dailyBestChain: _readInt(decoded['dailyBestChain']),
        bossWins: _readInt(decoded['bossWins']),
        achievements: _readStringSet(decoded['achievements']),
        bestThemeChains: _readIntMap(decoded['bestThemeChains']),
      );
    } on FormatException {
      return PlayerStats.empty();
    } on TypeError {
      return PlayerStats.empty();
    }
  }

  String toStoredJson() {
    return jsonEncode(<String, dynamic>{
      'bestEndlessChain': bestEndlessChain,
      'bestSpeedScore': bestSpeedScore,
      'bestSpeedWords': bestSpeedWords,
      'bestMemoryChain': bestMemoryChain,
      'bestThemeChain': bestThemeChain,
      'totalValidWords': totalValidWords,
      'totalHintsUsed': totalHintsUsed,
      'fastestAnswerMs': fastestAnswerMs,
      'dailyBestDate': dailyBestDate,
      'dailyBestChain': dailyBestChain,
      'bossWins': bossWins,
      'achievements': achievements.toList()..sort(),
      'bestThemeChains': bestThemeChains,
    });
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  static Set<String> _readStringSet(Object? value) {
    if (value is! List) {
      return <String>{};
    }
    return value.map((Object? item) => item.toString()).toSet();
  }

  static Map<String, int> _readIntMap(Object? value) {
    if (value is! Map) {
      return <String, int>{};
    }
    return value.map<String, int>(
      (Object? key, Object? mapValue) =>
          MapEntry<String, int>(key.toString(), _readInt(mapValue)),
    );
  }
}
