import 'package:flutter/material.dart';

/// Statistik user yang dipakai untuk mengevaluasi achievement.
class AchievementStats {
  final int reportsSubmitted;
  final int reportsCompleted;
  final int points;

  const AchievementStats({
    this.reportsSubmitted = 0,
    this.reportsCompleted = 0,
    this.points = 0,
  });
}

/// Definisi sebuah achievement statis.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  /// Predikat: apakah achievement terbuka untuk [AchievementStats] tertentu.
  final bool Function(AchievementStats stats) unlockedWhen;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedWhen,
  });

  bool isUnlockedFor(AchievementStats stats) => unlockedWhen(stats);
}

/// Pasangan achievement + status terbuka/terkunci.
class AchievementStatus {
  final Achievement achievement;
  final bool unlocked;

  const AchievementStatus(this.achievement, this.unlocked);
}

/// Katalog achievement SafeRoad dan evaluatornya.
class Achievements {
  Achievements._();

  /// Daftar achievement statis (urut dari paling mudah ke paling sulit).
  static final List<Achievement> all = [
    Achievement(
      id: 'first_report',
      title: 'Laporan Pertama',
      description: 'Kirim 1 laporan',
      icon: Icons.flag_outlined,
      unlockedWhen: (s) => s.reportsSubmitted >= 1,
    ),
    Achievement(
      id: 'reporter_10',
      title: 'Pelapor Aktif',
      description: 'Kirim 10 laporan',
      icon: Icons.campaign_outlined,
      unlockedWhen: (s) => s.reportsSubmitted >= 10,
    ),
    Achievement(
      id: 'finisher_5',
      title: 'Penyelesai',
      description: '5 laporan selesai',
      icon: Icons.task_alt_outlined,
      unlockedWhen: (s) => s.reportsCompleted >= 5,
    ),
    Achievement(
      id: 'points_100',
      title: 'Centurion',
      description: 'Kumpulkan 100 poin',
      icon: Icons.star_outline,
      unlockedWhen: (s) => s.points >= 100,
    ),
    Achievement(
      id: 'pro_reporter',
      title: 'Pro Reporter',
      description: 'Capai Level 5',
      icon: Icons.workspace_premium_outlined,
      unlockedWhen: (s) => s.points >= 400,
    ),
    Achievement(
      id: 'points_500',
      title: 'Pahlawan Jalan',
      description: 'Kumpulkan 500 poin',
      icon: Icons.military_tech_outlined,
      unlockedWhen: (s) => s.points >= 500,
    ),
  ];

  /// Evaluasi seluruh achievement untuk [stats].
  static List<AchievementStatus> evaluate(AchievementStats stats) =>
      all.map((a) => AchievementStatus(a, a.isUnlockedFor(stats))).toList();

  /// Jumlah achievement yang sudah terbuka.
  static int unlockedCount(AchievementStats stats) =>
      all.where((a) => a.isUnlockedFor(stats)).length;
}
