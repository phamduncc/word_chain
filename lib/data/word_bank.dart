import 'dart:math';

import '../models/game_models.dart';

class WordBank {
  static const String defaultStart = 'Bóng đá';
  static const String bossStart = 'Mạng lưới';

  static const Set<String> _blockedEnglishTerms = <String>{
    'internet',
    'web',
    'live',
    'show',
    'game',
    'boss',
    'combo',
    'online',
    'offline',
    'email',
    'mail',
    'chat',
    'server',
    'cloud',
  };

  static const List<String> dailyStarts = <String>[
    'Trí tuệ nhân tạo',
    'Mạng lưới',
    'Bóng đá',
    'Hà Nội',
    'Học tập',
    'Điện ảnh',
    'Khoa học',
  ];

  static const List<String> generalPhrases = <String>[
    'Trí tuệ tạo sinh',
    'Trợ lý hội thoại',
    'Mạng vạn vật',
    'Bóng đá',
    'Đá cầu',
    'Cầu khấn',
    'Cầu lông',
    'Cầu nguyện',
    'Cầu thủ',
    'Cầu treo',
    'Khấn nguyện',
    'Nguyện vọng',
    'Vọng cổ',
    'Cổ tích',
    'Tích cực',
    'Cực quang',
    'Quang học',
    'Học tập',
    'Học máy',
    'Học sinh',
    'Tập luyện',
    'Tập đọc',
    'Luyện trí nhớ',
    'Nhớ nhà',
    'Nhà sách',
    'Sách giáo khoa',
    'Khoa học',
    'Sinh viên',
    'Sinh trắc học',
    'Viên chức',
    'Chức năng',
    'Năng lượng',
    'Lượng giác',
    'Lượng tử',
    'Giác quan',
    'Quan sát',
    'Sát nhập',
    'Nhập môn',
    'Môn học',
    'Môn võ',
    'Học đường',
    'Đường phố',
    'Phố cổ',
    'Cổ động',
    'Động lực',
    'Lực lượng',
    'Tử tế',
    'Tế bào',
    'Bào chế',
    'Chế tạo',
    'Tạo hình',
    'Tạo mẫu',
    'Hình ảnh',
    'Ảnh viện',
    'Viện bảo tàng',
    'Tàng hình',
    'Máy chủ',
    'Chủ đề',
    'Đề xuất',
    'Xuất bản',
    'Bản đồ',
    'Đồ họa',
    'Họa sĩ',
    'Sĩ khí',
    'Khí công',
    'Công nghệ',
    'Nghệ thuật',
    'Thuật toán',
    'Thuật chiến',
    'Toán học',
    'Vật lý',
    'Lý thuyết',
    'Thuyết trình',
    'Trình duyệt',
    'Duyệt mạng',
    'Mạng động',
    'Động cơ',
    'Cơ sở dữ liệu',
    'Dữ liệu lớn',
    'Lớn mạnh',
    'Mạnh mẽ',
    'Mẽ ngoài',
    'Ngoài trời',
    'Trời đất',
    'Đất nước',
    'Nước mắm',
    'Mắm tôm',
    'Tôm hùm',
    'Hùm thiêng',
    'Thiêng liêng',
    'Liêng bài',
    'Bài học',
    'Đọc hiểu',
    'Hiểu bài',
    'Bài tập',
    'Viết luận',
    'Luận văn',
    'Văn học',
    'Phim trường',
    'Trường quay',
    'Quay phim',
    'Phim hoạt hình',
    'Hình tượng',
    'Tượng đài',
    'Đài truyền hình',
    'Hình sự',
    'Sự kiện',
    'Kiện tướng',
    'Tướng quân',
    'Quân cờ',
    'Cờ vua',
    'Vua phá lưới',
    'Lưới điện',
    'Điện toán đám mây',
    'Mây mù',
    'Mù chữ',
    'Chữ viết',
  ];

  static const Map<ChainTheme, List<String>> themePhrases =
      <ChainTheme, List<String>>{
        ChainTheme.sports: <String>[
          'Bóng đá',
          'Đá cầu',
          'Cầu thủ',
          'Cầu lông',
          'Thủ môn',
          'Môn võ',
          'Võ thuật',
          'Thuật chiến',
          'Chiến thuật',
          'Thuật ngữ thể thao',
          'Ngữ cảnh thi đấu',
          'Đấu kiếm',
          'Kiếm đạo',
          'Đạo cụ tập luyện',
          'Luyện thể lực',
          'Thể lực',
          'Lực sĩ',
          'Sĩ khí',
          'Khí công',
          'Công phá',
          'Phá bóng',
          'Bóng chuyền',
          'Chuyền bóng',
          'Bóng rổ',
          'Rổ bóng',
          'Bóng bàn',
          'Bàn thắng',
          'Thắng trận',
          'Trận đấu',
          'Đấu vật',
          'Vật tay',
          'Tay vợt',
          'Vợt bóng bàn',
          'Bàn cờ',
          'Cờ vua',
          'Vua phá lưới',
          'Lưới cầu môn',
        ],
        ChainTheme.geography: <String>[
          'Hà Nội',
          'Nội Mông',
          'Mông Cổ',
          'Cổ Loa',
          'Loa Thành',
          'Thành phố',
          'Phố cổ',
          'Cổ đô',
          'Đô thị',
          'Thị xã',
          'Xã đảo',
          'Đảo Phú Quốc',
          'Quốc gia',
          'Gia Lai',
          'Lai Châu',
          'Châu Á',
          'Á Đông',
          'Đông Nam Á',
          'Á châu',
          'Châu thổ',
          'Thổ nhưỡng',
          'Ngưỡng cửa biên giới',
          'Giới tuyến',
          'Tuyến phố',
          'Phố núi',
          'Núi rừng',
          'Rừng ngập mặn',
          'Mặn mòi biển cả',
          'Biển đảo',
          'Đảo quốc',
          'Quốc lộ',
          'Lộ trình',
          'Trình địa lý',
          'Địa lý',
          'Lý Sơn',
          'Sơn La',
          'La bàn',
          'Bàn đồ',
          'Đồ Sơn',
          'Sơn Tây',
          'Tây Nguyên',
          'Nguyên Bình',
        ],
        ChainTheme.technology: <String>[
          'Trí tuệ tạo sinh',
          'Trợ lý hội thoại',
          'Mạng vạn vật',
          'Vạn vật kết nối',
          'Nối mạng',
          'Mạng xã hội',
          'Hội thoại số',
          'Số hóa',
          'Hóa đơn điện tử',
          'Tử khóa',
          'Khóa bảo mật',
          'Mật khẩu',
          'Khẩu lệnh',
          'Lệnh máy',
          'Máy chủ',
          'Chủ đề',
          'Đề xuất',
          'Xuất dữ liệu',
          'Dữ liệu lớn',
          'Lớn mạnh',
          'Mạnh mẽ',
          'Mẽ ngoài',
          'Ngoài tuyến',
          'Tuyến cáp',
          'Cáp quang',
          'Quang học',
          'Học máy',
          'Máy học',
          'Học sâu',
          'Sâu mạng',
          'Mạng nơ ron',
          'Ron rỉ dữ liệu',
          'Liệu trình bảo trì',
          'Trì hoãn cập nhật',
          'Nhật ký hệ thống',
          'Thống kê',
          'Kê khai điện tử',
          'Trí tuệ nhân tạo',
          'Tạo hình',
          'Hình ảnh',
          'Ảnh số',
          'Số liệu',
          'Điện toán đám mây',
          'Mây máy chủ',
          'Chủ quản hệ thống',
        ],
        ChainTheme.entertainment: <String>[
          'Điện ảnh',
          'Ảnh viện',
          'Viện phim',
          'Phim trường',
          'Trường quay',
          'Quay phim',
          'Phim hoạt hình',
          'Hình tượng',
          'Tượng đài âm nhạc',
          'Nhạc kịch',
          'Kịch bản',
          'Bản thu',
          'Thu âm',
          'Âm nhạc',
          'Nhạc sĩ',
          'Sĩ diện sân khấu',
          'Khấu hài',
          'Hài kịch',
          'Kịch nói',
          'Nói cười',
          'Cười nghiêng ngả',
          'Ngả bài',
          'Bài hát',
          'Hát trực tiếp',
          'Tiếp sóng',
          'Sóng truyền hình',
          'Hình sự',
          'Sự kiện',
          'Kiện tướng cờ vua',
          'Vua phòng vé',
          'Vé xem phim',
          'Phim bộ',
          'Bộ phim',
          'Phim tài liệu',
          'Liệu pháp thư giãn',
          'Giãn cách sân khấu',
          'Sân khấu',
          'Khấu trừ vé',
        ],
        ChainTheme.study: <String>[
          'Học tập',
          'Tập đọc',
          'Đọc hiểu',
          'Hiểu bài',
          'Bài tập',
          'Tập viết',
          'Viết luận',
          'Luận văn',
          'Văn học',
          'Học sinh',
          'Sinh viên',
          'Viên chức',
          'Chức năng',
          'Năng lượng',
          'Lượng giác',
          'Giác quan',
          'Quan sát',
          'Sát hạch',
          'Hạch toán',
          'Toán học',
          'Học kỳ',
          'Kỳ thi',
          'Thi thử',
          'Thử nghiệm',
          'Nghiệm thu',
          'Thu bài',
          'Bài giảng',
          'Giảng viên',
          'Viên phấn',
          'Phấn đấu',
          'Đấu trí',
          'Trí nhớ',
          'Nhớ bài',
          'Bài học',
          'Học đường',
          'Đường vào đại học',
          'Đại học',
          'Học bổng',
          'Bổng lộc tri thức',
        ],
      };

  static List<String> allPhrases({ChainTheme? theme}) {
    final Set<String> phrases = <String>{...generalPhrases};
    if (theme != null) {
      phrases.addAll(themePhrases[theme] ?? const <String>[]);
    } else {
      for (final List<String> themeList in themePhrases.values) {
        phrases.addAll(themeList);
      }
    }
    return phrases.toList(growable: false)..sort();
  }

  static String randomStart({ChainTheme? theme, Random? random}) {
    final List<String> themeStarts = theme == null
        ? const <String>[]
        : themePhrases[theme] ?? const <String>[];
    final List<String> candidates = themeStarts.isEmpty
        ? allPhrases()
        : themeStarts;
    final List<String> allowedCandidates = candidates
        .where(isVietnamesePhraseAllowed)
        .toList(growable: false);
    final List<String> starts = allowedCandidates.isEmpty
        ? candidates
        : allowedCandidates;
    final Random randomizer = random ?? Random();
    return starts[randomizer.nextInt(starts.length)];
  }

  static String startForTheme(ChainTheme theme) {
    switch (theme) {
      case ChainTheme.sports:
        return 'Bóng đá';
      case ChainTheme.geography:
        return 'Hà Nội';
      case ChainTheme.technology:
        return 'Trí tuệ nhân tạo';
      case ChainTheme.entertainment:
        return 'Điện ảnh';
      case ChainTheme.study:
        return 'Học tập';
    }
  }

  static String dailyStartFor(DateTime date) {
    final int seed =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return dailyStarts[seed % dailyStarts.length];
  }

  static String dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static List<String> suggestionsFor(
    String requiredWord, {
    ChainTheme? theme,
    required Set<String> usedKeys,
    int limit = 3,
  }) {
    final String requiredKey = normalize(requiredWord);
    final List<String> candidates = allPhrases(theme: theme)
        .where(
          (String phrase) =>
              normalize(firstWord(phrase)) == requiredKey &&
              !usedKeys.contains(phraseKey(phrase)) &&
              isVietnamesePhraseAllowed(phrase),
        )
        .toList(growable: false);

    if (candidates.length <= limit) {
      return candidates;
    }

    return candidates.take(limit).toList(growable: false);
  }

  static String cleanPhrase(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String displayPhrase(String value) {
    final String clean = cleanPhrase(value);
    if (clean.isEmpty) {
      return clean;
    }
    return clean[0].toUpperCase() + clean.substring(1);
  }

  static String phraseKey(String phrase) => normalize(cleanPhrase(phrase));

  static String firstWord(String phrase) {
    final List<String> words = _words(phrase);
    return words.isEmpty ? '' : words.first;
  }

  static String lastWord(String phrase) {
    final List<String> words = _words(phrase);
    return words.isEmpty ? '' : words.last;
  }

  static bool startsWithRequiredWord(String phrase, String requiredWord) {
    return normalize(firstWord(phrase)) == normalize(requiredWord);
  }

  static bool isVietnamesePhraseAllowed(String phrase) {
    return blockedForeignToken(phrase) == null;
  }

  static String? blockedForeignToken(String phrase) {
    for (final String token in _words(phrase)) {
      final String normalized = normalize(token);
      final bool isUppercaseAbbreviation =
          token == token.toUpperCase() && RegExp(r'[A-Z]').hasMatch(token);

      if (normalized == 'ai' && isUppercaseAbbreviation) {
        return token;
      }

      if (_blockedEnglishTerms.contains(normalized) ||
          RegExp(r'[fjwzFJWZ]').hasMatch(token)) {
        return token;
      }
    }

    return null;
  }

  static String normalize(String input) {
    String value = cleanPhrase(input).toLowerCase();
    final Map<String, String> replacements = <String, String>{
      'a': 'áàảãạăắằẳẵặâấầẩẫậ',
      'e': 'éèẻẽẹêếềểễệ',
      'i': 'íìỉĩị',
      'o': 'óòỏõọôốồổỗộơớờởỡợ',
      'u': 'úùủũụưứừửữự',
      'y': 'ýỳỷỹỵ',
    };

    for (final MapEntry<String, String> entry in replacements.entries) {
      value = value.replaceAll(RegExp('[${entry.value}]'), entry.key);
    }

    return value.replaceAll('đ', 'd');
  }

  static List<String> _words(String phrase) {
    return cleanPhrase(phrase)
        .split(RegExp(r'\s+'))
        .map(_trimToken)
        .where((String word) => word.isNotEmpty)
        .toList(growable: false);
  }

  static String _trimToken(String token) {
    return token.replaceAll(
      RegExp(r'''^[\s,.;:!?()\[\]{}"'“”‘’]+|[\s,.;:!?()\[\]{}"'“”‘’]+$'''),
      '',
    );
  }
}
