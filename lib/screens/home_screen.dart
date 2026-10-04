import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';
import '../models/game_models.dart';
import '../services/local_stats_store.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.statsStore,
    required this.settings,
    required this.onSettingsChanged,
  });

  final LocalStatsStore statsStore;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<PlayerStats> _statsFuture;
  GameDifficulty _difficulty = GameDifficulty.medium;
  ChainTheme _theme = ChainTheme.sports;

  @override
  void initState() {
    super.initState();
    _statsFuture = widget.statsStore.load();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = widget.statsStore.load();
    });
  }

  Future<void> _openGame(GameConfig config) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => GameScreen(
          config: config,
          store: widget.statsStore,
          settings: widget.settings,
        ),
      ),
    );
    if (mounted) {
      _refreshStats();
    }
  }

  Future<void> _openStats() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => StatisticsScreen(
          store: widget.statsStore,
          settings: widget.settings,
        ),
      ),
    );
    if (mounted) {
      _refreshStats();
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SettingsScreen(
          initialSettings: widget.settings,
          onChanged: widget.onSettingsChanged,
        ),
      ),
    );
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[colors.primary, colors.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.link_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              copy.appName,
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          _AppBarIconButton(
            tooltip: copy.statistics,
            onPressed: _openStats,
            icon: Icons.bar_chart_rounded,
            colors: colors,
          ),
          const SizedBox(width: 6),
          _AppBarIconButton(
            tooltip: copy.settings,
            onPressed: _openSettings,
            icon: Icons.settings_rounded,
            colors: colors,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<PlayerStats>(
          future: _statsFuture,
          builder: (BuildContext context, AsyncSnapshot<PlayerStats> snapshot) {
            final PlayerStats stats = snapshot.data ?? PlayerStats.empty();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                _HeroBanner(stats: stats, settings: widget.settings),
                const SizedBox(height: 18),
                _SectionHeader(title: copy.difficulty),
                const SizedBox(height: 10),
                _DifficultySelector(
                  selected: _difficulty,
                  onChanged: (GameDifficulty d) {
                    setState(() => _difficulty = d);
                  },
                  colors: colors,
                ),
                const SizedBox(height: 18),
                _SectionHeader(title: copy.theme),
                const SizedBox(height: 10),
                _ThemePicker(
                  value: _theme,
                  label: copy.theme,
                  onChanged: (ChainTheme value) {
                    setState(() {
                      _theme = value;
                    });
                  },
                ),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: copy.isEnglish ? 'Game Modes' : 'Chế độ chơi',
                ),
                const SizedBox(height: 8),
                _ModeGrid(
                  children: <Widget>[
                    _ModeTile(
                      icon: Icons.all_inclusive_rounded,
                      title: copy.endless,
                      gradient: const <Color>[Color(0xFF6C3CE1), Color(0xFF9B63F8)],
                      onTap: () => _openGame(
                        GameConfig(
                          mode: GameMode.endless,
                          difficulty: _difficulty,
                          turnSeconds: widget.settings.answerSeconds,
                        ),
                      ),
                    ),
                    _ModeTile(
                      icon: Icons.speed_rounded,
                      title: copy.speed,
                      gradient: const <Color>[Color(0xFFE85D04), Color(0xFFFF9F1C)],
                      onTap: () => _openGame(
                        GameConfig(
                          mode: GameMode.speed,
                          difficulty: _difficulty,
                          turnSeconds: widget.settings.answerSeconds,
                          totalSeconds: 60,
                        ),
                      ),
                    ),
                    _ModeTile(
                      icon: Icons.psychology_alt_rounded,
                      title: copy.memory,
                      gradient: const <Color>[Color(0xFF0077B6), Color(0xFF00B4D8)],
                      onTap: () => _openGame(
                        GameConfig(
                          mode: GameMode.memory,
                          difficulty: _difficulty,
                          turnSeconds: widget.settings.answerSeconds,
                        ),
                      ),
                    ),
                    _ModeTile(
                      icon: Icons.groups_rounded,
                      title: copy.twoPlayers,
                      gradient: const <Color>[Color(0xFF2D6A4F), Color(0xFF52B788)],
                      onTap: () => _openGame(
                        GameConfig(
                          mode: GameMode.twoPlayer,
                          difficulty: _difficulty,
                          turnSeconds: widget.settings.answerSeconds,
                        ),
                      ),
                    ),
                    _ModeTile(
                      icon: _themeIcon(_theme),
                      title: _theme.label,
                      gradient: const <Color>[Color(0xFFAD1457), Color(0xFFE91E8C)],
                      onTap: () => _openGame(
                        GameConfig(
                          mode: GameMode.theme,
                          difficulty: _difficulty,
                          turnSeconds: widget.settings.answerSeconds,
                          theme: _theme,
                        ),
                      ),
                    ),
                    _ModeTile(
                      icon: Icons.today_rounded,
                      title: copy.daily,
                      gradient: const <Color>[Color(0xFF1565C0), Color(0xFF42A5F5)],
                      onTap: () => _openGame(
                        GameConfig(
                          mode: GameMode.daily,
                          difficulty: _difficulty,
                          turnSeconds: widget.settings.answerSeconds,
                        ),
                      ),
                    ),
                    _ModeTile(
                      icon: Icons.workspace_premium_rounded,
                      title: copy.bigChallenge,
                      gradient: const <Color>[Color(0xFFB7791F), Color(0xFFECC94B)],
                      onTap: () => _openGame(
                        GameConfig(
                          mode: GameMode.boss,
                          difficulty: GameDifficulty.hard,
                          turnSeconds: widget.settings.answerSeconds,
                          totalSeconds: 60,
                          targetCorrectWords: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _StatsButton(onPressed: _openStats, copy: copy, colors: colors),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── App Bar Icon Button ──────────────────────────────────────────────────────

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.colors,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.stats, required this.settings});

  final PlayerStats stats;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppCopy copy = AppCopy.of(settings.language);
    final String fastest = stats.fastestAnswerMs == 0
        ? '--'
        : '${(stats.fastestAnswerMs / 1000).toStringAsFixed(1)}s';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              colors.primary,
              Color.lerp(colors.primary, colors.tertiary, 0.7)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Vòng trang trí góc phải-trên
            Positioned(
              right: -28,
              top: -28,
              child: Container(
                width: 110,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Vòng trang trí góc phải-dưới
            Positioned(
              right: 40,
              bottom: -45,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Vòng trang trí góc trái-dưới
            Positioned(
              left: -25,
              bottom: -25,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Nội dung chính
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          copy.smartTitle,
                          style: GoogleFonts.baloo2(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${stats.achievements.length}/${achievementDefinitions.length}',
                              style: GoogleFonts.baloo2(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _HeroStat(
                          icon: Icons.link_rounded,
                          label: copy.records,
                          value: '${stats.bestEndlessChain}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroStat(
                          icon: Icons.today_rounded,
                          label: copy.day,
                          value: '${stats.dailyBestChain}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeroStat(
                          icon: Icons.flash_on_rounded,
                          label: copy.fast,
                          value: fastest,
                        ),
                      ),
                    ],
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

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.baloo2(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.0,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.baloo2(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
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

// ─── Difficulty Selector ──────────────────────────────────────────────────────

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({
    required this.selected,
    required this.onChanged,
    required this.colors,
  });

  final GameDifficulty selected;
  final ValueChanged<GameDifficulty> onChanged;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: GameDifficulty.values.map((GameDifficulty d) {
        final bool isSelected = d == selected;
        final Color diffColor = _difficultyColor(d);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: d == GameDifficulty.values.first ? 0 : 5,
              right: d == GameDifficulty.values.last ? 0 : 5,
            ),
            child: GestureDetector(
              onTap: () => onChanged(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: isSelected
                      ? diffColor
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? diffColor : colors.outlineVariant,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: diffColor.withValues(alpha: 0.38),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      _difficultyIcon(d),
                      size: 17,
                      color: isSelected
                          ? Colors.white
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      d.label,
                      style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _difficultyColor(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return const Color(0xFF22C55E);
      case GameDifficulty.medium:
        return const Color(0xFFF59E0B);
      case GameDifficulty.hard:
        return const Color(0xFFEF4444);
    }
  }

  IconData _difficultyIcon(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Icons.sentiment_satisfied_alt_rounded;
      case GameDifficulty.medium:
        return Icons.timer_10_rounded;
      case GameDifficulty.hard:
        return Icons.whatshot_rounded;
    }
  }
}

// ─── Theme Picker ─────────────────────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final ChainTheme value;
  final String label;
  final ValueChanged<ChainTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return DropdownButtonFormField<ChainTheme>(
      value: value,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.category_rounded, color: colors.primary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: ChainTheme.values
          .map(
            (ChainTheme theme) => DropdownMenuItem<ChainTheme>(
              value: theme,
              child: Row(
                children: <Widget>[
                  Icon(_themeIcon(theme), size: 20, color: colors.primary),
                  const SizedBox(width: 10),
                  Text(
                    theme.label,
                    style: GoogleFonts.baloo2(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
      onChanged: (ChainTheme? theme) {
        if (theme != null) {
          onChanged(theme);
        }
      },
    );
  }
}

// ─── Mode Grid ────────────────────────────────────────────────────────────────

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 620) {
          final List<Widget> rowChildren = <Widget>[];
          for (int index = 0; index < children.length; index += 1) {
            rowChildren.add(SizedBox(width: 136, child: children[index]));
            if (index != children.length - 1) {
              rowChildren.add(const SizedBox(width: 10));
            }
          }

          return SizedBox(
            height: 112,
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              child: Row(children: rowChildren),
            ),
          );
        }

        final int crossAxisCount = constraints.maxWidth >= 900 ? 5 : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: constraints.maxWidth >= 900 ? 1.65 : 1.45,
          children: children,
        );
      },
    );
  }
}

// ─── Mode Tile ────────────────────────────────────────────────────────────────

class _ModeTile extends StatefulWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  State<_ModeTile> createState() => _ModeTileState();
}

class _ModeTileState extends State<_ModeTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              // Vòng trang trí
              Positioned(
                right: -14,
                top: -14,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Nội dung
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 22),
                    ),
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.baloo2(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stats Button ─────────────────────────────────────────────────────────────

class _StatsButton extends StatelessWidget {
  const _StatsButton({
    required this.onPressed,
    required this.copy,
    required this.colors,
  });

  final VoidCallback onPressed;
  final AppCopy copy;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.primary, width: 1.5),
        foregroundColor: colors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.query_stats_rounded),
      label: Text(copy.statistics),
    );
  }
}

// ─── Theme Icon Helper ────────────────────────────────────────────────────────

IconData _themeIcon(ChainTheme theme) {
  switch (theme) {
    case ChainTheme.sports:
      return Icons.sports_soccer_rounded;
    case ChainTheme.geography:
      return Icons.public_rounded;
    case ChainTheme.technology:
      return Icons.memory_rounded;
    case ChainTheme.entertainment:
      return Icons.movie_creation_rounded;
    case ChainTheme.study:
      return Icons.menu_book_rounded;
  }
}
