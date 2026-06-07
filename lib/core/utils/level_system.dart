/// Sistem level kontribusi SafeRoad (Tahap 6).
///
/// Level & tier DIHITUNG dari poin kontribusi user — tidak disimpan terpisah.
/// Aturan: setiap [pointsPerLevel] poin menaikkan 1 level.
class LevelSystem {
  LevelSystem._();

  /// Jumlah poin untuk naik satu level.
  static const int pointsPerLevel = 100;

  /// Level dari total [points]. Level minimum adalah 1.
  static int levelFromPoints(int points) {
    if (points <= 0) return 1;
    return (points ~/ pointsPerLevel) + 1;
  }

  /// Nama tier berdasarkan [level].
  ///
  /// - `Pemula`        : Level < 3
  /// - `Kontributor`   : Level 3–4
  /// - `Pro Reporter`  : Level 5+
  static String tierName(int level) {
    if (level >= 5) return 'Pro Reporter';
    if (level >= 3) return 'Kontributor';
    return 'Pemula';
  }

  /// Tier langsung dari poin.
  static String tierFromPoints(int points) =>
      tierName(levelFromPoints(points));

  /// Poin yang sudah terkumpul di dalam level saat ini (0..[pointsPerLevel]).
  static int pointsIntoLevel(int points) =>
      (points <= 0 ? 0 : points) % pointsPerLevel;

  /// Sisa poin menuju level berikutnya.
  static int pointsToNextLevel(int points) =>
      pointsPerLevel - pointsIntoLevel(points);

  /// Progres menuju level berikutnya, dalam rentang 0.0–1.0.
  static double levelProgress(int points) =>
      pointsIntoLevel(points) / pointsPerLevel;
}
