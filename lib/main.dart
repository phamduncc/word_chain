import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_settings.dart';
import 'screens/home_screen.dart';
import 'services/local_settings_store.dart';
import 'services/local_stats_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  runApp(
    WordChainApp(
      statsStore: LocalStatsStore(preferences),
      settingsStore: LocalSettingsStore(preferences),
    ),
  );
}

class WordChainApp extends StatefulWidget {
  const WordChainApp({
    super.key,
    required this.statsStore,
    required this.settingsStore,
  });

  final LocalStatsStore statsStore;
  final LocalSettingsStore settingsStore;

  @override
  State<WordChainApp> createState() => _WordChainAppState();
}

class _WordChainAppState extends State<WordChainApp> {
  AppSettings _settings = AppSettings.defaults();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final AppSettings settings = await widget.settingsStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
    });
  }

  Future<void> _updateSettings(AppSettings settings) async {
    setState(() {
      _settings = settings;
    });
    await widget.settingsStore.save(settings);
  }

  @override
  Widget build(BuildContext context) {
    // Màu tím indigo – đặc trưng của game nối từ thông minh
    const Color seed = Color(0xFF4F35D2);

    return MaterialApp(
      title: AppCopy.of(_settings.language).appName,
      debugShowCheckedModeBanner: false,
      themeMode: _settings.themePreference.themeMode,
      theme: _buildTheme(seed, Brightness.light),
      darkTheme: _buildTheme(seed, Brightness.dark),
      home: HomeScreen(
        statsStore: widget.statsStore,
        settings: _settings,
        onSettingsChanged: _updateSettings,
      ),
    );
  }

  ThemeData _buildTheme(Color seed, Brightness brightness) {
    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    // Nền tối sâu hơn cho dark mode – cảm giác game chuyên nghiệp
    if (brightness == Brightness.dark) {
      colorScheme = colorScheme.copyWith(
        surface: const Color(0xFF0C0A1E),
        surfaceContainerLowest: const Color(0xFF07050F),
        surfaceContainerLow: const Color(0xFF13102A),
        surfaceContainer: const Color(0xFF1B1836),
        surfaceContainerHigh: const Color(0xFF232042),
        surfaceContainerHighest: const Color(0xFF2D294E),
      );
    }

    final TextTheme baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    // Font Baloo 2 – hỗ trợ tiếng Việt, phong cách game sinh động
    final TextTheme appTextTheme = GoogleFonts.baloo2TextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: appTextTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: colorScheme.surfaceContainerLow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle: GoogleFonts.baloo2(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle: GoogleFonts.baloo2(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.baloo2(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.baloo2(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelStyle: GoogleFonts.baloo2(fontWeight: FontWeight.w600),
      ),
    );
  }
}
