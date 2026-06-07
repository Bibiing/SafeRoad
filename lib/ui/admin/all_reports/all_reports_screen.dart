import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/view_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/notification_repository.dart';
import '../../../domain/repository/report_repository.dart';
import 'all_reports_viewmodel.dart';

/// Layar daftar semua laporan untuk Admin.
class AllReportsScreen extends StatelessWidget {
  const AllReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AllReportsViewModel(
        reportRepository: ctx.read<ReportRepository>(),
        notificationRepository: ctx.read<NotificationRepository>(),
        authRepository: ctx.read<AuthRepository>(),
        adminUid: ctx.read<AuthRepository>().currentUserId,
      )..fetchAllReports(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SafeRoad Admin', style: AppTextStyles.caption),
              Text('Manajemen Laporan', style: AppTextStyles.title),
            ],
          ),
          actions: [
            Consumer<AllReportsViewModel>(
              builder: (context, vm, _) => IconButton(
                onPressed: vm.isLoading ? null : vm.exportToCsv,
                icon: const Icon(Icons.download),
                tooltip: 'Ekspor CSV',
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const _SearchAndFilterBar(),
            Expanded(
              child: Consumer<AllReportsViewModel>(
                builder: (context, vm, child) {
                  if (vm.isLoading) {
                    return const LoadingIndicator(
                      message: 'Memuat laporan...',
                    );
                  }

                  if (vm.status == ViewStatus.failure) {
                    return ErrorState(
                      message: vm.error ?? 'Gagal mengambil data.',
                      onRetry: vm.fetchAllReports,
                    );
                  }

                  final reports = vm.filteredReports;

                  if (reports.isEmpty) {
                    return const EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Tidak ada laporan ditemukan.',
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: vm.fetchAllReports,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: reports.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _ReportCard(report: reports[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AllReportsViewModel>();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: vm.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Cari judul atau alamat...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatusChip(
                  label: 'Semua',
                  selected: vm.filterStatus == null,
                  onTap: () => vm.setFilterStatus(null),
                ),
                ...ReportStatus.values.map((status) {
                  return _StatusChip(
                    label: status.label,
                    selected: vm.filterStatus == status,
                    onTap: () => vm.setFilterStatus(status),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip filter status bergaya pil (hijau saat terpilih, dengan centang).
class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primaryTint : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_circle,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AllReportsViewModel>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(status: report.status),
                const Spacer(),
                Text(
                  report.category.label,
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(report.title, style: AppTextStyles.subtitle),
            const SizedBox(height: 4),
            Text(report.address, style: AppTextStyles.caption),

            // Tampilkan alasan admin jika ada.
            if (report.effectiveAdminReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Catatan Admin: ${report.effectiveAdminReason}',
                  style: AppTextStyles.caption
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const SizedBox(height: 16),
            PopupMenuButton<ReportStatus>(
              onSelected: (newStatus) =>
                  _handleStatusChange(context, vm, newStatus),
              itemBuilder: (context) => ReportStatus.values.map((s) {
                return PopupMenuItem(value: s, child: Text(s.label));
              }).toList(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ubah Status',
                      style: AppTextStyles.button,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.onPrimary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStatusChange(
    BuildContext context,
    AllReportsViewModel vm,
    ReportStatus newStatus,
  ) async {
    String? reason;

    // Minta alasan bila ditolak atau butuh keterangan tambahan.
    if (newStatus == ReportStatus.rejected ||
        newStatus == ReportStatus.inProgress) {
      reason = await showDialog<String>(
        context: context,
        builder: (context) => _ReasonDialog(status: newStatus),
      );
      if (reason == null) return; // User membatalkan dialog.
    }

    final ok = await vm.updateStatus(report, newStatus, reason: reason);
    if (context.mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Gagal memperbarui status')),
      );
    }
  }
}

class _ReasonDialog extends StatefulWidget {
  final ReportStatus status;
  const _ReasonDialog({required this.status});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.status == ReportStatus.rejected
            ? 'Alasan Penolakan'
            : 'Catatan Proses',
      ),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Tulis keterangan di sini...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
