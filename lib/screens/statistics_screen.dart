import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';
import '../models/game_models.dart';
import '../services/local_stats_store.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.store,
    required this.settings,
  });

  final LocalStatsStore store;
  final AppSettings settings;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<PlayerStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = widget.store.load();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppCopy copy = AppCopy.of(widget.settings.language);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[colors.primary, colors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              copy.statistics,
              style: GoogleFonts.baloo2(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<PlayerStats>(
          future: _statsFuture,
          builder: (BuildContext context, AsyncSnapshot<PlayerStats> snapshot) {
            final PlayerStats stats = snapshot.data ?? PlayerStats.empty();
            final String fastest = stats.fastestAnswerMs == 0
                ? '--'
                : '${(stats.fastestAnswerMs / 1000).toStringAsFixed(1)}s';

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                // Banner thống kê nổi bật
                _StatsBanner(stats: stats, colors: colors, copy: copy),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: copy.records,
                  icon: Icons.emoji_events_rounded,
                  colors: colors,
                ),
                const SizedBox(height: 10),
                _StatCard(
                  icon: Icons.all_inclusive_rounded,
                  iconColor: const Color(0xFF6C3CE1),
                  title: copy.endless,
                  value: '${stats.bestEndlessChain}',
                  subtitle: copy.chain,
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFFE85D04),
                  title: copy.speedScore,
                  value: '${stats.bestSpeedScore}',
                  subtitle: copy.score,
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.psychology_alt_rounded,
                  iconColor: const Color(0xFF0077B6),
                  title: copy.memory,
                  value: '${stats.bestMemoryChain}',
                  subtitle: copy.chain,
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.category_rounded,
                  iconColor: const Color(0xFFAD1457),
                  title: copy.theme,
                  value: '${stats.bestThemeChain}',
                  subtitle: copy.chain,
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.today_rounded,
                  iconColor: const Color(0xFF1565C0),
                  title: '${copy.day} ${stats.dailyBestDate}',
                  value: '${stats.dailyBestChain}',
                  subtitle: copy.chain,
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.flash_on_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: copy.fastest,
                  value: fastest,
                  subtitle: '',
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.lightbulb_rounded,
                  iconColor: const Color(0xFF52B788),
                  title: copy.hintsUsed,
                  value: '${stats.totalHintsUsed}',
                  subtitle: '',
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _StatCard(
                  icon: Icons.workspace_premium_rounded,
                  iconColor: const Color(0xFFB7791F),
                  title: copy.bigChallengeWins,
                  value: '${stats.bossWins}',
                  subtitle: copy.isEnglish ? 'wins' : 'lần thắng',
                  colors: colors,
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: copy.achievements,
                  icon: Icons.military_tech_rounded,
                  colors: colors,
                ),
                const SizedBox(height: 10),
                ...achievementDefinitions.map((AchievementDefinition achievement) {
                  final bool unlocked = stats.achievements.contains(achievement.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AchievementCard(
                      achievement: achievement,
                      unlocked: unlocked,
                      colors: colors,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Stats Banner ─────────────────────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  const _StatsBanner({
    required this.stats,
    required this.colors,
    required this.copy,
  });

  final PlayerStats stats;
  final ColorScheme colors;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final int unlocked = stats.achievements.length;
    final int total = achievementDefinitions.length;
    final double progress = total > 0 ? unlocked / total : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              colors.primary,
              Color.lerp(colors.primary, colors.tertiary, 0.65)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          copy.isEnglish
                              ? 'Your Progress'
                              : 'Thành tích của bạn',
                          style: GoogleFonts.baloo2(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '$unlocked/$total 🏆',
                        style: GoogleFonts.baloo2(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.colors,
  });

  final String title;
  final IconData icon;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[colors.primary, colors.tertiary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.baloo2(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.colors,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: colors.onSurface,
                  height: 1.0,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: GoogleFonts.baloo2(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Achievement Card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.unlocked,
    required this.colors,
  });

  final AchievementDefinition achievement;
  final bool unlocked;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked
            ? colors.tertiaryContainer.withValues(alpha: 0.35)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? colors.tertiary.withValues(alpha: 0.45)
              : colors.outlineVariant.withValues(alpha: 0.5),
          width: unlocked ? 1.5 : 1,
        ),
        boxShadow: unlocked
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.tertiary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: unlocked
                  ? LinearGradient(
                      colors: <Color>[
                        colors.tertiary,
                        Color.lerp(colors.tertiary, colors.primary, 0.4)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: unlocked ? null : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              unlocked
                  ? Icons.emoji_events_rounded
                  : Icons.lock_outline_rounded,
              color: unlocked ? Colors.white : colors.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  achievement.title,
                  style: GoogleFonts.baloo2(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: unlocked
                        ? colors.onTertiaryContainer
                        : colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.subtitle,
                  style: GoogleFonts.baloo2(
                    fontSize: 12,
                    color: unlocked
                        ? colors.onTertiaryContainer.withValues(alpha: 0.7)
                        : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.tertiary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: colors.tertiary,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}
