import 'package:intl/intl.dart';

/// Utilitas format tanggal dalam Bahasa Indonesia.
class DateFormatter {
  DateFormatter._();

  /// Format lengkap: "30 Mei 2026, 14:30"
  static String full(DateTime date) {
    return DateFormat('d MMMM yyyy, HH:mm', 'id').format(date);
  }

  /// Format pendek: "30 Mei 2026"
  static String short(DateTime date) {
    return DateFormat('d MMM yyyy', 'id').format(date);
  }

  /// Format relatif: "2 jam lalu", "Kemarin", dll.
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 2) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return short(date);
  }
}
