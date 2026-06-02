import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_viewmodel.dart';
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
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0.5,
          actions: [
            IconButton(
              onPressed: () => context.read<AuthRepository>().signOut(),
              icon: const Icon(Icons.logout, color: Colors.red),
            ),
          ],
        ),
        body: Consumer<AdminDashboardViewModel>(
          builder: (context, vm, child) {
            if (vm.status == ViewStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: vm.loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Ringkasan Laporan', style: AppTextStyles.subtitle),
                  const SizedBox(height: 16),
                  
                  // ── Grid Statistik ──
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _StatCard(
                        label: 'Total',
                        value: vm.totalReports,
                        color: AppColors.primary,
                        icon: Icons.assignment,
                      ),
                      _StatCard(
                        label: 'Menunggu',
                        value: vm.pendingReports,
                        color: Colors.orange,
                        icon: Icons.hourglass_empty,
                      ),
                      _StatCard(
                        label: 'Diproses',
                        value: vm.inProgressReports,
                        color: Colors.blue,
                        icon: Icons.engineering,
                      ),
                      _StatCard(
                        label: 'Selesai',
                        value: vm.completedReports,
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Tombol Navigasi ──
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AllReportsScreen()),
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Kelola Semua Laporan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: AppTextStyles.heading.copyWith(color: color, fontSize: 24),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
