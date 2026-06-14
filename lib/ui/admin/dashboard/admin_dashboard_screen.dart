import 'package:saferoad/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../additional/statistics/statistics_screen.dart';
import '../all_reports/all_reports_screen.dart';
import 'admin_dashboard_viewmodel.dart';

/// Dashboard utama untuk Admin.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDashboardViewModel(
        reportRepository: context.read<ReportRepository>(),
      )..loadDashboard(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Dasbor Admin'),
              const SizedBox(width: 8),
              const _AdminBadge(),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => context.read<AuthRepository>().signOut(),
              icon: const Icon(Icons.logout, color: AppColors.error),
              tooltip: 'Keluar',
            ),
          ],
        ),
        body: Consumer<AdminDashboardViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const LoadingIndicator(message: 'Memuat data...');
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: vm.loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (vm.hasNewReports) ...[
                    _NewReportBanner(
                      count: vm.newReportsCount,
                      latestTitle: vm.latestNewReport?.title,
                      onTap: () {
                        vm.clearNewReportNotification();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AllReportsScreen(),
                          ),
                        );
                      },
                      onDismiss: vm.clearNewReportNotification,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Grid Statistik ──
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.15,
                    children: [
                      _StatCard(
                        label: 'Total Laporan',
                        value: vm.totalReports,
                        color: AppColors.primary,
                        icon: Icons.assignment_outlined,
                      ),
                      _StatCard(
                        label: 'Menunggu',
                        value: vm.pendingReports,
                        color: AppColors.statusPending,
                        icon: Icons.hourglass_empty,
                      ),
                      _StatCard(
                        label: 'Diproses',
                        value: vm.inProgressReports,
                        color: AppColors.statusInProgress,
                        icon: Icons.engineering,
                      ),
                      _StatCard(
                        label: 'Selesai',
                        value: vm.completedReports,
                        color: AppColors.statusCompleted,
                        icon: Icons.check_circle,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Tombol Navigasi ──
                  PrimaryButton(
                    label: 'Kelola Semua Laporan',
                    icon: Icons.list_alt,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AllReportsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StatisticsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart_rounded),
                    label: const Text('Lihat Statistik'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Lencana kecil "Admin" — pembeda peran halus tanpa mengganti warna AppBar.
class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.appColors.primaryTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Admin',
        style: AppTextStyles.badge.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _NewReportBanner extends StatelessWidget {
  final int count;
  final String? latestTitle;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NewReportBanner({
    required this.count,
    required this.latestTitle,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final title = count == 1
        ? 'Ada laporan baru masuk'
        : 'Ada $count laporan baru masuk';
    final subtitle = latestTitle == null || latestTitle!.isEmpty
        ? 'Ketuk untuk melihat daftar laporan.'
        : latestTitle!;

    return Material(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: AppTextStyles.badge.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textSecondary,
                tooltip: 'Tutup',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radius + 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style:
                    AppTextStyles.heading.copyWith(color: color, fontSize: 34),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
