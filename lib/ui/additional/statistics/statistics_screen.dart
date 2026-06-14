import 'package:saferoad/core/theme/app_colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/view_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/status_helper.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/section_title.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/repository/report_repository.dart';
import 'statistics_viewmodel.dart';

/// Layar ringkasan statistik laporan (per status & per kategori).
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => StatisticsViewModel(
        reportRepository: ctx.read<ReportRepository>(),
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Statistik Laporan')),
        body: Consumer<StatisticsViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingIndicator(message: 'Menghitung statistik...');
            }
            if (vm.status == ViewStatus.failure) {
              return ErrorState(
                message: vm.error ?? 'Gagal memuat statistik.',
                onRetry: vm.load,
              );
            }
            if (vm.total == 0) {
              return const EmptyState(
                icon: Icons.bar_chart,
                title: 'Belum ada data.',
                subtitle: 'Statistik muncul setelah ada laporan masuk.',
              );
            }

            final statusCounts = vm.countByStatus;
            final categoryCounts = vm.countByCategory;
            final maxStatus = statusCounts.values.fold<int>(0, _max);
            final maxCategory = categoryCounts.values.fold<int>(0, _max);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: vm.load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _TotalCard(total: vm.total),
                  const SizedBox(height: 24),
                  const SectionTitle('Berdasarkan Status'),
                  const SizedBox(height: 12),
                  ...ReportStatus.values.map(
                    (status) => _StatBar(
                      label: status.label,
                      count: statusCounts[status] ?? 0,
                      max: maxStatus,
                      color: StatusHelper.colorOf(status),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle('Berdasarkan Kategori'),
                  const SizedBox(height: 12),
                  ...ReportCategory.values.map(
                    (category) => _StatBar(
                      label: category.label,
                      count: categoryCounts[category] ?? 0,
                      max: maxCategory,
                      color: AppColors.primary,
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

  static int _max(int a, int b) => a > b ? a : b;
}

class _TotalCard extends StatelessWidget {
  final int total;

  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.appColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$total',
                style: AppTextStyles.heading.copyWith(color: AppColors.primary),
              ),
              Text('Total Laporan', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bar horizontal sederhana — panjang proporsional terhadap [max].
class _StatBar extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final Color color;

  const _StatBar({
    required this.label,
    required this.count,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : count / max;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 22, color: context.appColors.background),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction.clamp(0.0, 1.0),
                    child: Container(
                      height: 22,
                      color: color.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: AppTextStyles.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}
