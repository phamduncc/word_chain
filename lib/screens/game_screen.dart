import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/word_bank.dart';
import '../models/app_settings.dart';
import '../models/game_models.dart';
import '../services/local_stats_store.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.config,
    required this.store,
    required this.settings,
  });

  final GameConfig config;
  final LocalStatsStore store;
  final AppSettings settings;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final Random _random = Random();

  Timer? _timer;
  late List<WordChain> _chain;
  late Set<String> _usedPhraseKeys;
  late int _turnRemaining;
  late int? _totalRemaining;
  late DateTime _turnStartedAt;
  late String _dailyKey;

  int _score = 0;
  int _combo = 1;
  int _hintsUsed = 0;
  int _fastestAnswerMs = 0;
  int _currentPlayerIndex = 0;
  List<int> _playerScores = <int>[0, 0];
  List<int> _playerCorrectWords = <int>[0, 0];
  bool _ended = false;
  bool _paused = false;
  bool _memoryHidden = false;
  String _feedback = '';
  List<String> _suggestions = <String>[];

  GameConfig get _config => widget.config;
  AppCopy get _copy => AppCopy.of(widget.settings.language);
  int get _correctWords => max(0, _chain.length - 1);
  bool get _usesCombo =>
      _config.mode == GameMode.speed || _config.mode == GameMode.boss;
  bool get _isTwoPlayer => _config.mode == GameMode.twoPlayer;
  String get _requiredWord => WordBank.lastWord(_chain.last.phrase);

  @override
  void initState() {
    super.initState();
    _setupRound();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  String _startPhraseForRound() {
    switch (_config.mode) {
      case GameMode.theme:
        return WordBank.randomStart(theme: _config.theme, random: _random);
      case GameMode.endless:
      case GameMode.speed:
      case GameMode.memory:
      case GameMode.daily:
      case GameMode.boss:
      case GameMode.twoPlayer:
        return WordBank.randomStart(random: _random);
    }
  }

  void _setupRound() {
    final DateTime now = DateTime.now();
    final WordChain start = WordChain(
      phrase: _startPhraseForRound(),
      createdAt: now,
    );

    _chain = <WordChain>[start];
    _usedPhraseKeys = <String>{WordBank.phraseKey(start.phrase)};
    _turnRemaining = _config.effectiveTurnSeconds;
    _totalRemaining = _config.totalSeconds;
    _turnStartedAt = now;
    _dailyKey = WordBank.dateKey(now);
    _score = 0;
    _combo = 1;
    _hintsUsed = 0;
    _fastestAnswerMs = 0;
    _currentPlayerIndex = 0;
    _playerScores = <int>[0, 0];
    _playerCorrectWords = <int>[0, 0];
    _ended = false;
    _paused = false;
    _memoryHidden = false;
    _feedback = '';
    _suggestions = <String>[];
    _inputController.clear();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _ended || _paused) {
        return;
      }

      setState(() {
        if (_totalRemaining != null) {
          _totalRemaining = max(0, _totalRemaining! - 1);
        }
        _turnRemaining = max(0, _turnRemaining - 1);
      });

      if (_totalRemaining == 0) {
        final bool bossCompleted =
            _config.mode == GameMode.boss &&
            _correctWords >= (_config.targetCorrectWords ?? 20);
        _finishGame(
          bossCompleted ? _copy.challengeComplete : _copy.timeOutRun,
          completedBoss: bossCompleted,
        );
        return;
      }

      if (_turnRemaining == 0) {
        _finishGame(_copy.timeOutTurn);
      }
    });
  }

  void _submitInput() {
    if (_ended || _memoryHidden) {
      return;
    }

    final String rawPhrase = WordBank.cleanPhrase(_inputController.text);
    if (rawPhrase.isEmpty) {
      _reject(_copy.emptyInput);
      return;
    }

    final String phrase = WordBank.displayPhrase(rawPhrase);
    final String? blockedToken = WordBank.blockedForeignToken(phrase);
    if (blockedToken != null) {
      _reject(_copy.onlyVietnamese(blockedToken));
      return;
    }

    final String phraseKey = WordBank.phraseKey(phrase);

    if (_usedPhraseKeys.contains(phraseKey)) {
      _reject(_copy.repeatedPhrase);
      return;
    }

    if (!WordBank.startsWithRequiredWord(phrase, _requiredWord)) {
      _reject(_copy.mustStartWith(_requiredWord));
      return;
    }

    final DateTime now = DateTime.now();
    final int elapsedMs = max(1, now.difference(_turnStartedAt).inMilliseconds);

    setState(() {
      _chain.add(WordChain(phrase: phrase, createdAt: now));
      _usedPhraseKeys.add(phraseKey);
      _inputController.clear();
      _suggestions = <String>[];
      _feedback = _copy.correctPhrase(phrase);

      if (_fastestAnswerMs == 0 || elapsedMs < _fastestAnswerMs) {
        _fastestAnswerMs = elapsedMs;
      }

      final int earnedPoints = _pointsForAcceptedPhrase();
      _score += earnedPoints;
      if (_isTwoPlayer) {
        _playerScores[_currentPlayerIndex] += earnedPoints;
        _playerCorrectWords[_currentPlayerIndex] += 1;
        _currentPlayerIndex = (_currentPlayerIndex + 1) % 2;
      }

      if (_usesCombo) {
        _combo += 1;
      }

      _turnRemaining = _config.effectiveTurnSeconds;
      _turnStartedAt = DateTime.now();
    });

    if (_config.mode == GameMode.boss &&
        _correctWords >= (_config.targetCorrectWords ?? 20)) {
      _finishGame(_copy.challengeComplete, completedBoss: true);
      return;
    }

    if (_config.usesMemoryQuiz && _chain.length % 5 == 0) {
      _showMemoryQuiz();
      return;
    }

    _inputFocusNode.requestFocus();
  }

  int _pointsForAcceptedPhrase() {
    switch (_config.mode) {
      case GameMode.speed:
        return 10 * _combo;
      case GameMode.boss:
        return 15 * _combo;
      case GameMode.endless:
      case GameMode.memory:
      case GameMode.theme:
      case GameMode.daily:
      case GameMode.twoPlayer:
        return 10 * _chainMultiplier;
    }
  }

  int get _chainMultiplier {
    if (_chain.length <= 10) {
      return 1;
    }
    if (_chain.length <= 20) {
      return 2;
    }
    return 3;
  }

  void _reject(String message) {
    setState(() {
      _feedback = message;
      if (_usesCombo) {
        _combo = 1;
      }
    });
  }

  void _showHints() {
    if (_ended || _memoryHidden) {
      return;
    }

    if (!_config.difficulty.allowsHints) {
      _reject(_copy.hardNoHints);
      return;
    }

    final List<String> hints = WordBank.suggestionsFor(
      _requiredWord,
      theme: _config.theme,
      usedKeys: _usedPhraseKeys,
    );

    if (hints.isEmpty) {
      _reject(_copy.noHints);
      return;
    }

    setState(() {
      if (_suggestions.isEmpty) {
        _hintsUsed += 1;
        if (!_config.difficulty.hasFreeHints) {
          _score = max(0, _score - 5);
          if (_usesCombo) {
            _combo = max(1, _combo - 1);
          }
        }
      }
      _suggestions = hints;
      _feedback = _copy.hintFor(_requiredWord);
    });
  }

  void _useSuggestion(String phrase) {
    _inputController.text = phrase;
    _inputController.selection = TextSelection.collapsed(
      offset: _inputController.text.length,
    );
    _inputFocusNode.requestFocus();
  }

  Future<void> _showMemoryQuiz() async {
    if (_ended) {
      return;
    }

    setState(() {
      _paused = true;
      _memoryHidden = true;
      _feedback = _copy.checkingMemory;
    });

    final bool askPhrase = _random.nextBool();
    final int phraseIndex = _random.nextInt(_chain.length);
    final TextEditingController answerController = TextEditingController();
    final String question = askPhrase
        ? _copy.memoryPhraseQuestion(phraseIndex + 1)
        : _copy.memoryLengthQuestion;

    final String? answer = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _MemoryQuizDialog(
          title: _copy.memoryCheck,
          question: question,
          answerController: answerController,
          isPhrase: askPhrase,
          replyLabel: _copy.reply,
          answerLabel: _copy.answer,
        );
      },
    );
    answerController.dispose();

    if (!mounted || _ended) {
      return;
    }

    final bool correct = askPhrase
        ? WordBank.phraseKey(answer ?? '') ==
              WordBank.phraseKey(_chain[phraseIndex].phrase)
        : int.tryParse((answer ?? '').trim()) == _chain.length;

    if (!correct) {
      setState(() {
        _memoryHidden = false;
      });
      await _finishGame(_copy.wrongMemory);
      return;
    }

    setState(() {
      _memoryHidden = false;
      _paused = false;
      _score += 25;
      _feedback = _copy.memoryCorrect;
      _turnRemaining = _config.effectiveTurnSeconds;
      _turnStartedAt = DateTime.now();
    });
    _inputFocusNode.requestFocus();
  }

  String get _twoPlayerOutcome {
    if (_playerScores[0] == _playerScores[1]) {
      return _copy.draw;
    }

    return _copy.winner(_playerScores[0] > _playerScores[1] ? 1 : 2);
  }

  Future<void> _finishGame(String reason, {bool completedBoss = false}) async {
    if (_ended) {
      return;
    }

    _timer?.cancel();
    setState(() {
      _ended = true;
      _paused = true;
      _memoryHidden = false;
      _feedback = reason;
    });

    final List<AchievementDefinition> unlocked = await widget.store.recordResult(
      GameResult(
        mode: _config.mode,
        chainLength: _chain.length,
        correctWords: _correctWords,
        score: _score,
        hintsUsed: _hintsUsed,
        fastestAnswerMs: _fastestAnswerMs,
        theme: _config.theme,
        completedBoss: completedBoss,
        dailyKey: _config.mode == GameMode.daily ? _dailyKey : null,
      ),
    );

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _GameOverDialog(
          completedBoss: completedBoss,
          reason: reason,
          chain: _chain,
          correctWords: _correctWords,
          score: _score,
          isTwoPlayer: _isTwoPlayer,
          twoPlayerOutcome: _twoPlayerOutcome,
          playerScores: _playerScores,
          playerCorrectWords: _playerCorrectWords,
          unlocked: unlocked,
          copy: _copy,
          onHome: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop(true);
          },
          onRestart: () {
            Navigator.of(dialogContext).pop();
            _restart();
          },
        );
      },
    );
  }

  void _restart() {
    _timer?.cancel();
    setState(_setupRound);
    _startTimer();
    _inputFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool positiveFeedback =
        _feedback.startsWith(_copy.correctPhrase('')) ||
        _feedback == _copy.memoryCorrect;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _copy.modeTitle(_config.mode),
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                height: 1.1,
              ),
            ),
            Text(
              _config.difficulty.label,
              style: GoogleFonts.baloo2(
                fontSize: 12,
                color: colors.onSurfaceVariant,
                height: 1.1,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: _copy.finish,
            onPressed: _ended
                ? null
                : () async {
                    await _finishGame(_copy.endedByUser);
                  },
            icon: Icon(
              Icons.flag_rounded,
              color: _ended ? colors.onSurfaceVariant : colors.error,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _StatusBar(
                turnRemaining: _turnRemaining,
                turnTotal: _config.effectiveTurnSeconds,
                totalRemaining: _totalRemaining,
                score: _score,
                chainLength: _chain.length,
                combo: _usesCombo ? _combo : null,
                copy: _copy,
              ),
              if (_isTwoPlayer) ...<Widget>[
                const SizedBox(height: 12),
                _TwoPlayerScoreboard(
                  playerScores: _playerScores,
                  playerCorrectWords: _playerCorrectWords,
                  currentPlayerIndex: _currentPlayerIndex,
                  copy: _copy,
                ),
              ],
              const SizedBox(height: 14),
              _CurrentPhrasePanel(
                hidden: _memoryHidden,
                phrase: _chain.last.phrase,
                requiredWord: _requiredWord,
                colors: colors,
                copy: _copy,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _inputController,
                focusNode: _inputFocusNode,
                enabled: !_ended && !_memoryHidden,
                textInputAction: TextInputAction.done,
                style: GoogleFonts.baloo2(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: _copy.newPhrase,
                  prefixIcon: Icon(
                    Icons.edit_rounded,
                    color: colors.primary,
                  ),
                ),
                onSubmitted: (_) => _submitInput(),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _ended || _memoryHidden ? null : _submitInput,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(_copy.send),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _ended || _memoryHidden ? null : _showHints,
                      icon: const Icon(Icons.lightbulb_rounded, size: 18),
                      label: Text(_copy.hint),
                    ),
                  ),
                ],
              ),
              if (_suggestions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions
                      .map(
                        (String suggestion) => ActionChip(
                          avatar: Icon(
                            Icons.north_east_rounded,
                            size: 14,
                            color: colors.primary,
                          ),
                          label: Text(suggestion),
                          onPressed: () => _useSuggestion(suggestion),
                          backgroundColor: colors.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _feedback.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _FeedbackBanner(
                          feedback: _feedback,
                          isPositive: positiveFeedback,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _copy.history,
                    style: GoogleFonts.baloo2(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_chain.length}',
                      style: GoogleFonts.baloo2(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_memoryHidden)
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.visibility_off_rounded,
                          color: colors.onSurfaceVariant,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _copy.hiddenChain,
                          style: GoogleFonts.baloo2(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _HistoryList(chain: _chain),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feedback Banner ──────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.feedback,
    required this.isPositive,
  });

  final String feedback;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPositive
            ? colors.primaryContainer.withValues(alpha: 0.55)
            : colors.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPositive
              ? colors.primary.withValues(alpha: 0.35)
              : colors.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isPositive ? colors.primary : colors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feedback,
              style: GoogleFonts.baloo2(
                color: isPositive ? colors.primary : colors.error,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Bar ───────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.turnRemaining,
    required this.turnTotal,
    required this.totalRemaining,
    required this.score,
    required this.chainLength,
    required this.combo,
    required this.copy,
  });

  final int turnRemaining;
  final int turnTotal;
  final int? totalRemaining;
  final int score;
  final int chainLength;
  final int? combo;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool urgentTurn = turnRemaining <= 3;
    final bool urgentTotal = totalRemaining != null && totalRemaining! <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: urgentTurn
            ? colors.errorContainer.withValues(alpha: 0.4)
            : colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: urgentTurn
              ? colors.error.withValues(alpha: 0.5)
              : colors.outlineVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: <Widget>[
          _CircularTimer(
            remaining: turnRemaining,
            total: turnTotal,
            urgent: urgentTurn,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _StatusPill(
                  icon: Icons.star_rounded,
                  value: '$score',
                  highlight: score > 0,
                ),
                _StatusPill(
                  icon: Icons.link_rounded,
                  value: '$chainLength',
                ),
                if (combo != null)
                  _StatusPill(
                    icon: Icons.bolt_rounded,
                    value: 'x$combo',
                    highlight: combo! > 2,
                  ),
                if (totalRemaining != null)
                  _StatusPill(
                    icon: Icons.hourglass_top_rounded,
                    value: '${totalRemaining}s',
                    urgent: urgentTotal,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Circular Timer ───────────────────────────────────────────────────────────

class _CircularTimer extends StatelessWidget {
  const _CircularTimer({
    required this.remaining,
    required this.total,
    required this.urgent,
  });

  final int remaining;
  final int total;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double progress = total > 0 ? remaining / total : 0.0;

    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Vòng nền
          SizedBox(
            width: 62,
            height: 62,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 5,
              color: (urgent ? colors.error : colors.primary)
                  .withValues(alpha: 0.15),
            ),
          ),
          // Vòng tiến trình
          SizedBox(
            width: 62,
            height: 62,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(
                urgent ? colors.error : colors.primary,
              ),
            ),
          ),
          // Số đếm ngược
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$remaining',
                style: GoogleFonts.baloo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: urgent ? colors.error : colors.onSurface,
                  height: 1.0,
                ),
              ),
              Text(
                's',
                style: GoogleFonts.baloo2(
                  fontSize: 10,
                  color: urgent ? colors.error : colors.onSurfaceVariant,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Status Pill ─────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.value,
    this.urgent = false,
    this.highlight = false,
  });

  final IconData icon;
  final String value;
  final bool urgent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color foreground = urgent
        ? colors.error
        : highlight
            ? colors.tertiary
            : colors.onSurface;
    final Color background = urgent
        ? colors.errorContainer
        : highlight
            ? colors.tertiaryContainer
            : colors.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: (urgent || highlight)
            ? Border.all(color: foreground.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.baloo2(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Two-Player Scoreboard ────────────────────────────────────────────────────

class _TwoPlayerScoreboard extends StatelessWidget {
  const _TwoPlayerScoreboard({
    required this.playerScores,
    required this.playerCorrectWords,
    required this.currentPlayerIndex,
    required this.copy,
  });

  final List<int> playerScores;
  final List<int> playerCorrectWords;
  final int currentPlayerIndex;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              copy.currentPlayer(currentPlayerIndex + 1),
              style: GoogleFonts.baloo2(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _PlayerScoreTile(
                label: copy.player(1),
                score: playerScores[0],
                correctWords: playerCorrectWords[0],
                active: currentPlayerIndex == 0,
                colors: colors,
                copy: copy,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'VS',
                style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: _PlayerScoreTile(
                label: copy.player(2),
                score: playerScores[1],
                correctWords: playerCorrectWords[1],
                active: currentPlayerIndex == 1,
                colors: colors,
                copy: copy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlayerScoreTile extends StatelessWidget {
  const _PlayerScoreTile({
    required this.label,
    required this.score,
    required this.correctWords,
    required this.active,
    required this.colors,
    required this.copy,
  });

  final String label;
  final int score;
  final int correctWords;
  final bool active;
  final ColorScheme colors;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final Color background =
        active ? colors.primaryContainer : colors.surfaceContainerHighest;
    final Color foreground =
        active ? colors.onPrimaryContainer : colors.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? colors.primary : colors.outlineVariant,
          width: active ? 1.5 : 1,
        ),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.person_rounded, size: 16, color: foreground),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.baloo2(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$score ${copy.score}',
            style: GoogleFonts.baloo2(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          Text(
            '$correctWords ${copy.correctWords}',
            style: GoogleFonts.baloo2(
              color: foreground.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Current Phrase Panel ─────────────────────────────────────────────────────

class _CurrentPhrasePanel extends StatelessWidget {
  const _CurrentPhrasePanel({
    required this.hidden,
    required this.phrase,
    required this.requiredWord,
    required this.colors,
    required this.copy,
  });

  final bool hidden;
  final String phrase;
  final String requiredWord;
  final ColorScheme colors;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hidden
            ? colors.surfaceContainerHighest.withValues(alpha: 0.5)
            : colors.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hidden
              ? colors.outlineVariant
              : colors.primary.withValues(alpha: 0.4),
          width: hidden ? 1 : 1.5,
        ),
        boxShadow: hidden
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: hidden
          ? Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.visibility_off_rounded,
                    color: colors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    copy.memoryCheckingTitle,
                    style: GoogleFonts.baloo2(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  copy.currentPhrase,
                  style: GoogleFonts.baloo2(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phrase,
                  style: GoogleFonts.baloo2(
                    color: colors.onPrimaryContainer,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      copy.isEnglish ? 'Next starts with:' : 'Tiếp theo bắt đầu bằng:',
                      style: GoogleFonts.baloo2(
                        fontSize: 12,
                        color: colors.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        requiredWord.toUpperCase(),
                        style: GoogleFonts.baloo2(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ─── History List ─────────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.chain});

  final List<WordChain> chain;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chain.length,
      itemBuilder: (BuildContext context, int index) {
        final WordChain item = chain[index];
        final bool isLatest = index == chain.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isLatest
                  ? colors.primaryContainer.withValues(alpha: 0.6)
                  : colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLatest
                    ? colors.primary.withValues(alpha: 0.5)
                    : colors.outlineVariant.withValues(alpha: 0.5),
                width: isLatest ? 1.5 : 1,
              ),
              boxShadow: isLatest
                  ? <BoxShadow>[
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: <Widget>[
                // Số thứ tự
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isLatest
                        ? LinearGradient(
                            colors: <Color>[colors.primary, colors.tertiary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isLatest ? null : colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.baloo2(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isLatest
                          ? Colors.white
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.phrase,
                    style: GoogleFonts.baloo2(
                      fontWeight: isLatest
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 14,
                      color: isLatest
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                    ),
                  ),
                ),
                Icon(
                  isLatest
                      ? Icons.radio_button_checked
                      : Icons.check_circle_outline,
                  color: isLatest
                      ? colors.primary
                      : colors.onSurfaceVariant.withValues(alpha: 0.4),
                  size: isLatest ? 20 : 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Memory Quiz Dialog ───────────────────────────────────────────────────────

class _MemoryQuizDialog extends StatelessWidget {
  const _MemoryQuizDialog({
    required this.title,
    required this.question,
    required this.answerController,
    required this.isPhrase,
    required this.replyLabel,
    required this.answerLabel,
  });

  final String title;
  final String question;
  final TextEditingController answerController;
  final bool isPhrase;
  final String replyLabel;
  final String answerLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.baloo2(fontWeight: FontWeight.w800, fontSize: 17),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            question,
            style: GoogleFonts.baloo2(fontSize: 14),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: answerController,
            autofocus: true,
            keyboardType: isPhrase ? TextInputType.text : TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: answerLabel,
              prefixIcon: const Icon(Icons.psychology_alt_rounded),
            ),
            onSubmitted: (_) {
              Navigator.of(context).pop(answerController.text);
            },
          ),
        ],
      ),
      actions: <Widget>[
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(answerController.text);
          },
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text(replyLabel),
        ),
      ],
    );
  }
}

// ─── Game Over Dialog ─────────────────────────────────────────────────────────

class _GameOverDialog extends StatelessWidget {
  const _GameOverDialog({
    required this.completedBoss,
    required this.reason,
    required this.chain,
    required this.correctWords,
    required this.score,
    required this.isTwoPlayer,
    required this.twoPlayerOutcome,
    required this.playerScores,
    required this.playerCorrectWords,
    required this.unlocked,
    required this.copy,
    required this.onHome,
    required this.onRestart,
  });

  final bool completedBoss;
  final String reason;
  final List<WordChain> chain;
  final int correctWords;
  final int score;
  final bool isTwoPlayer;
  final String twoPlayerOutcome;
  final List<int> playerScores;
  final List<int> playerCorrectWords;
  final List<AchievementDefinition> unlocked;
  final AppCopy copy;
  final VoidCallback onHome;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: <Widget>[
          Text(
            completedBoss ? '🏆' : '🎮',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 10),
          Text(
            completedBoss ? copy.victory : copy.gameOver,
            style: GoogleFonts.baloo2(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Lý do kết thúc
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: completedBoss
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reason,
                style: GoogleFonts.baloo2(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: completedBoss
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Thống kê
            _DialogStatRow(
              icon: Icons.link_rounded,
              label: copy.chain,
              value: '${chain.length}',
              colors: colors,
            ),
            const SizedBox(height: 8),
            _DialogStatRow(
              icon: Icons.check_circle_outline,
              label: copy.correctWords,
              value: '$correctWords',
              colors: colors,
            ),
            const SizedBox(height: 8),
            _DialogStatRow(
              icon: Icons.star_rounded,
              label: copy.score,
              value: '$score',
              colors: colors,
              highlight: true,
            ),
            if (isTwoPlayer) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      twoPlayerOutcome,
                      style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: colors.onTertiaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${copy.player(1)}: ${playerScores[0]} - ${playerCorrectWords[0]} ${copy.correctWords}',
                      style: GoogleFonts.baloo2(fontSize: 12),
                    ),
                    Text(
                      '${copy.player(2)}: ${playerScores[1]} - ${playerCorrectWords[1]} ${copy.correctWords}',
                      style: GoogleFonts.baloo2(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            if (unlocked.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    copy.newAchievement,
                    style: GoogleFonts.baloo2(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ...unlocked.map(
                (AchievementDefinition achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: <Widget>[
                      const Text('🏅', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: GoogleFonts.baloo2(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: onHome,
          icon: const Icon(Icons.home_rounded, size: 18),
          label: Text(copy.home),
        ),
        FilledButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(copy.playAgain),
        ),
      ],
    );
  }
}

class _DialogStatRow extends StatelessWidget {
  const _DialogStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 18,
          color: highlight ? colors.primary : colors.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.baloo2(
            fontSize: 13,
            color: colors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.baloo2(
            fontSize: highlight ? 18 : 14,
            fontWeight: FontWeight.w800,
            color: highlight ? colors.primary : colors.onSurface,
          ),
        ),
      ],
    );
  }
}
