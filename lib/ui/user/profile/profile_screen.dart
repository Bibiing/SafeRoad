import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/achievements.dart';
import '../../../core/widgets/google_logo.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/section_title.dart';
import '../../../domain/model/user.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_screen.dart';
import 'profile_viewmodel.dart';

/// Tab Profil — info user, tier/level, statistik kontribusi, achievement.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ProfileViewModel(
      authRepository: context.read<AuthRepository>(),
      reportRepository: context.read<ReportRepository>(),
    );
    _vm.loadProfile();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _vm.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message, style: AppTextStyles.body.copyWith(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/images/logo-saferoad.png',
        width: 48,
        height: 48,
        fit: BoxFit.contain,
      ),
      children: [
        const SizedBox(height: 8),
        Text(AppConstants.appTagline, style: AppTextStyles.body.copyWith(fontSize: 14)),
      ],
    );
  }

  void _showAchievement(AchievementStatus status) {
    final a = status.achievement;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              a.icon,
              color: status.unlocked ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(a.title)),
          ],
        ),
        content: Text(
          status.unlocked
              ? '${a.description}\n\nTerbuka. Kerja bagus!'
              : '${a.description}\n\nBelum terbuka.',
          style: AppTextStyles.body.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        body: SafeArea(
          child: Consumer<ProfileViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const LoadingIndicator();
              }

              final user = vm.user;
              if (user == null) {
                return Center(
                  child: Text(
                    vm.error ?? 'Gagal memuat profil.',
                    style: AppTextStyles.body,
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text('Profil', style: AppTextStyles.heading),
                  const SizedBox(height: 20),

                  _ProfileHeader(user: user, tier: vm.tier),
                  const SizedBox(height: 16),

                  _MethodRow(level: vm.level, user: user),
                  const SizedBox(height: 24),

                  _StatsCard(
                    submitted: vm.reportsSubmitted,
                    completed: vm.reportsCompleted,
                    points: vm.contributionPoints,
                  ),
                  const SizedBox(height: 16),

                  _PointsCard(
                    points: vm.contributionPoints,
                    level: vm.level,
                    progress: vm.levelProgress,
                    pointsToNext: vm.pointsToNextLevel,
                  ),
                  const SizedBox(height: 28),

                  const SectionTitle('Achievements'),
                  const SizedBox(height: 12),
                  _AchievementsRow(
                    items: vm.achievements,
                    onTap: _showAchievement,
                  ),
                  const SizedBox(height: 28),

                  _MenuItem(
                    icon: Icons.help_outline,
                    label: 'Bantuan',
                    onTap: () => _showInfo(
                      'Bantuan',
                      'Buat laporan dengan tombol "Buat Laporan", pantau statusnya di "Laporan Saya", dan kumpulkan poin kontribusi.',
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    label: 'Tentang SafeRoad',
                    onTap: _showAbout,
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Avatar inisial + lencana tier + nama + email.
class _ProfileHeader extends StatelessWidget {
  final AppUser user;
  final String tier;

  const _ProfileHeader({required this.user, required this.tier});

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    // Foto profil Google hanya ditampilkan bila user login via Google dan
    // memiliki photoUrl; selain itu (email/password atau Google tanpa foto)
    // jatuh ke avatar inisial hijau.
    final hasPhoto = user.isGoogleProvider && (user.photoUrl?.isNotEmpty ?? false);

    Widget initialAvatar() => Container(
          color: AppColors.primaryTint,
          alignment: Alignment.center,
          child: Text(
            initial,
            style: AppTextStyles.heading.copyWith(
              fontSize: 38,
              color: AppColors.primary,
            ),
          ),
        );

    return Column(
      children: [
        SizedBox(
          height: 104,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                alignment: Alignment.center,
                child: hasPhoto
                    ? Image.network(
                        user.photoUrl!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        // Placeholder inisial saat foto masih dimuat.
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : initialAvatar(),
                        // Fallback otomatis ke inisial bila gagal memuat (offline/URL rusak).
                        errorBuilder: (_, _, _) => initialAvatar(),
                      )
                    : Text(
                        initial,
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 38,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Text(
                    tier,
                    style: AppTextStyles.badge.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(user.name, style: AppTextStyles.heading.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(user.email, style: AppTextStyles.caption),
      ],
    );
  }
}

/// Baris "Metode Masuk" + Level pill + provider chip.
class _MethodRow extends StatelessWidget {
  final int level;
  final AppUser user;

  const _MethodRow({required this.level, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Level $level',
            style: AppTextStyles.badge.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Text('Metode Masuk', style: AppTextStyles.caption),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.isGoogleProvider)
                const GoogleLogo(size: 14)
              else
                const Icon(Icons.email_outlined,
                    size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                user.providerLabel,
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kartu statistik 3 kolom.
class _StatsCard extends StatelessWidget {
  final int submitted;
  final int completed;
  final int points;

  const _StatsCard({
    required this.submitted,
    required this.completed,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.send_outlined,
              value: '$submitted',
              label: 'Laporan Dikirim',
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.check_circle_outline,
              value: '$completed',
              label: 'Laporan Selesai',
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.star_outline,
              value: '$points',
              label: 'Poin Kontribusi',
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 44, color: AppColors.border);
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.title.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

/// Kartu Poin & Level: progres menuju level berikutnya + cara mendapatkan poin.
class _PointsCard extends StatelessWidget {
  final int points;
  final int level;
  final double progress;
  final int pointsToNext;

  const _PointsCard({
    required this.points,
    required this.level,
    required this.progress,
    required this.pointsToNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Poin & Level', style: AppTextStyles.subtitle),
              const Spacer(),
              Text(
                '$points poin',
                style:
                    AppTextStyles.subtitle.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $level', style: AppTextStyles.caption),
              Text('Level ${level + 1}', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primaryTint,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$pointsToNext poin lagi menuju Level ${level + 1}',
            style: AppTextStyles.caption,
          ),
          const Divider(height: 28),
          Text(
            'Cara mendapatkan poin',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const _PointRule(
            icon: Icons.add_circle_outline,
            label: 'Membuat laporan',
            points: '+10',
          ),
          const SizedBox(height: 10),
          const _PointRule(
            icon: Icons.verified_outlined,
            label: 'Laporan diverifikasi admin',
            points: '+5',
          ),
          const SizedBox(height: 10),
          const _PointRule(
            icon: Icons.check_circle_outline,
            label: 'Laporan selesai diperbaiki',
            points: '+25',
          ),
        ],
      ),
    );
  }
}

/// Satu baris aturan poin: ikon + keterangan + nilai poin.
class _PointRule extends StatelessWidget {
  final IconData icon;
  final String label;
  final String points;

  const _PointRule({
    required this.icon,
    required this.label,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 14)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            points,
            style: AppTextStyles.badge.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

/// Deret lencana achievement horizontal.
class _AchievementsRow extends StatelessWidget {
  final List<AchievementStatus> items;
  final ValueChanged<AchievementStatus> onTap;

  const _AchievementsRow({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final unlocked = item.unlocked;
          return GestureDetector(
            onTap: () => onTap(item),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? AppColors.primaryTint
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: unlocked ? AppColors.primary : AppColors.border,
                      width: unlocked ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(
                    item.achievement.icon,
                    color: unlocked ? AppColors.primary : AppColors.textHint,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    item.achievement.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: unlocked
                          ? AppColors.textSecondary
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Baris menu pengaturan.
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: AppTextStyles.body)),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
