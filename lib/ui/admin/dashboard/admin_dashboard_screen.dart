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
