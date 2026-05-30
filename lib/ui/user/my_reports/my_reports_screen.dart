import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../report_detail/report_detail_screen.dart';
import 'my_reports_viewmodel.dart';

/// Tab Laporan Saya — daftar laporan milik user yang login.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late final MyReportsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = MyReportsViewModel(
      reportRepository: context.read<ReportRepository>(),
      authRepository: context.read<AuthRepository>(),
    );
    _vm.loadMyReports();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        appBar: AppBar(title: const Text('Laporan Saya')),
        body: Consumer<MyReportsViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingIndicator(message: 'Memuat laporan...');
            }
            if (vm.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vm.error!, style: AppTextStyles.body),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => vm.loadMyReports(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }
            if (vm.reports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 64,
                        color: AppColors.textHint.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada laporan.\nBuat laporan pertamamu!',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => vm.loadMyReports(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vm.reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = vm.reports[index];
                  return _MyReportCard(
                    report: report,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ReportDetailScreen(reportId: report.id),
                        ),
                      );
                      _vm.loadMyReports();
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MyReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;

  const _MyReportCard({required this.report, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: AppTextStyles.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(status: report.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(report.category.label, style: AppTextStyles.caption),
              if (report.address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  report.address,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                DateFormatter.relative(report.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
