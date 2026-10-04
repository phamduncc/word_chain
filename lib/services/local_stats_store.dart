import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_models.dart';

class LocalStatsStore {
  LocalStatsStore(this._preferences);

  static const String _statsKey = 'word_chain.player_stats.v1';

  final SharedPreferences _preferences;

  Future<PlayerStats> load() async {
    return PlayerStats.fromStoredJson(_preferences.getString(_statsKey));
  }

  Future<List<AchievementDefinition>> recordResult(GameResult result) async {
    final PlayerStats stats = await load();
    final Set<String> before = Set<String>.from(stats.achievements);

    stats.totalValidWords += result.correctWords;
    stats.totalHintsUsed += result.hintsUsed;

    if (result.fastestAnswerMs > 0) {
      stats.fastestAnswerMs = stats.fastestAnswerMs == 0
          ? result.fastestAnswerMs
          : min(stats.fastestAnswerMs, result.fastestAnswerMs);
    }

    switch (result.mode) {
      case GameMode.endless:
        stats.bestEndlessChain = max(
          stats.bestEndlessChain,
          result.chainLength,
        );
      case GameMode.speed:
        stats.bestSpeedScore = max(stats.bestSpeedScore, result.score);
        stats.bestSpeedWords = max(stats.bestSpeedWords, result.correctWords);
      case GameMode.memory:
        stats.bestMemoryChain = max(stats.bestMemoryChain, result.chainLength);
      case GameMode.theme:
        stats.bestThemeChain = max(stats.bestThemeChain, result.chainLength);
      case GameMode.daily:
        _recordDaily(stats, result);
      case GameMode.boss:
        if (result.completedBoss) {
          stats.bossWins += 1;
        }
      case GameMode.twoPlayer:
        break;
    }

    final ChainTheme? theme = result.theme;
    if (theme != null) {
      final String key = theme.name;
      stats.bestThemeChains[key] = max(
        stats.bestThemeChains[key] ?? 0,
        result.chainLength,
      );
    }

    _unlockAchievements(stats, result);
    await _preferences.setString(_statsKey, stats.toStoredJson());

    return achievementDefinitions
        .where(
          (AchievementDefinition achievement) =>
              stats.achievements.contains(achievement.id) &&
              !before.contains(achievement.id),
        )
        .toList(growable: false);
  }

  Future<void> reset() async {
    await _preferences.remove(_statsKey);
  }

  void _recordDaily(PlayerStats stats, GameResult result) {
    final String today = result.dailyKey ?? '';
    if (today.isEmpty || stats.dailyBestDate != today) {
      stats.dailyBestDate = today;
      stats.dailyBestChain = result.chainLength;
      return;
    }

    stats.dailyBestChain = max(stats.dailyBestChain, result.chainLength);
  }

  void _unlockAchievements(PlayerStats stats, GameResult result) {
    if (result.chainLength >= 10) {
      stats.achievements.add('chain_10');
    }
    if (result.chainLength >= 50) {
      stats.achievements.add('chain_50');
    }
    if (result.hintsUsed == 0 && result.correctWords >= 5) {
      stats.achievements.add('no_hint');
    }
    if (result.fastestAnswerMs > 0 && result.fastestAnswerMs <= 3000) {
      stats.achievements.add('under_3_seconds');
    }
    if ((stats.bestThemeChains[ChainTheme.sports.name] ?? 0) >= 10) {
      stats.achievements.add('sports_expert');
    }
    if (result.completedBoss) {
      stats.achievements.add('boss_badge');
    }
  }
}
