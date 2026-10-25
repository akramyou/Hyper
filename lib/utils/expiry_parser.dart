class ExpiryParser {
  static DateTime? parse(String text) {
    text = text.trim().replaceAll(RegExp(r'[^\d/\-.: ]'), ' ');
    final patterns = [
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
      RegExp(r'(\d{1,2})-(\d{1,2})-(\d{4})'),
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
      RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})'),
      RegExp(r'(\d{1,2})/(\d{4})'),
      RegExp(r'(\d{4})/(\d{1,2})'),
    ];
    for (final regExp in patterns) {
      final match = regExp.firstMatch(text);
      if (match != null) {
        try {
          final g1 = int.parse(match.group(1)!);
          final g2 = int.parse(match.group(2)!);
          final g3 = match.groupCount >= 3 ? int.parse(match.group(3)!) : null;
          if (g3 != null) {
            if (g1 > 31) {
              return DateTime(g1, g2, 1);
            }
            return DateTime(g3, g2, g1);
          } else {
            return DateTime(g2, g1, 1);
          }
        } catch (_) {}
      }
    }
    return null;
  }
}
