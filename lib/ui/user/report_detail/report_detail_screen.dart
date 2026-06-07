import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/status_helper.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/model/report_status_log.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import '../edit_report/edit_report_screen.dart';
import 'report_detail_viewmodel.dart';

/// Layar detail laporan dengan timeline status vertikal.
class ReportDetailScreen extends StatelessWidget {
  /// ID laporan yang ditampilkan.
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ReportDetailViewModel(
        reportRepository: ctx.read<ReportRepository>(),
        authRepository: ctx.read<AuthRepository>(),
      )..loadReport(reportId),
      child: const _DetailBody(),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody();

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text(
          'Hapus laporan ini? Tindakan tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final vm = context.read<ReportDetailViewModel>();
    final ok = await vm.deleteReport();
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Gagal menghapus.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportDetailViewModel>();

    if (vm.isLoading && vm.report == null) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Memuat detail...'),
      );
    }

    final report = vm.report;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            vm.error ?? 'Laporan tidak ditemukan.',
            style: AppTextStyles.body,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        actions: [
          if (vm.canEdit) ...[
            IconButton(
              tooltip: 'Edit',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditReportScreen(report: report),
                  ),
                );
                vm.loadReport(report.id);
              },
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Hapus',
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Foto ──
          if (report.imageUrls.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                report.imageUrls.first,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: AppColors.primaryTint,
                  child: const Icon(Icons.broken_image,
                      size: 48, color: AppColors.textHint),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Judul + Status ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(report.title, style: AppTextStyles.heading),
              ),
              const SizedBox(width: 8),
              StatusPill(status: report.status),
            ],
          ),
          const SizedBox(height: 16),

          // ── Field Info ──
          _InfoField(label: 'Kategori', value: report.category.label),
          _InfoField(label: 'Deskripsi', value: report.description),
          _InfoField(
            label: 'Lokasi',
            value: report.address.isNotEmpty
                ? '${report.address}\n${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}'
                : '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}',
          ),
          _InfoField(
            label: 'Dibuat',
            value: DateFormatter.full(report.createdAt),
          ),
          if (report.effectiveAdminReason != null)
            _InfoField(
              label: report.status == ReportStatus.rejected
                  ? 'Alasan Ditolak'
                  : 'Catatan Admin',
              value: report.effectiveAdminReason!,
              valueColor: report.status == ReportStatus.rejected
                  ? AppColors.error
                  : AppColors.primary,
            ),

          // ── Timeline Status ──
          const SizedBox(height: 24),
          Text('Riwayat Status', style: AppTextStyles.title),
          const SizedBox(height: 12),
          if (vm.statusLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(StatusHelper.iconOf(report.status),
                      color: StatusHelper.colorOf(report.status), size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.status.label, style: AppTextStyles.subtitle),
                      Text(
                        DateFormatter.full(report.createdAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            _StatusTimeline(logs: vm.statusLogs),
        ],
      )
          .animate()
          .fade(duration: 400.ms)
          .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
    );
  }
}

/// Field informasi (label + value) dengan divider.
class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}

/// Timeline vertikal status laporan.
class _StatusTimeline extends StatelessWidget {
  final List<ReportStatusLog> logs;

  const _StatusTimeline({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(logs.length, (index) {
        final log = logs[index];
        final isLast = index == logs.length - 1;
        final color = StatusHelper.colorOf(log.status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dot + Line ──
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ── Content ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.status.label, style: AppTextStyles.subtitle),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.full(log.timestamp),
                        style: AppTextStyles.caption,
                      ),
                      if (log.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          log.note,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
