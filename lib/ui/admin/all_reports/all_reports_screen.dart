import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import '../../auth/login/login_viewmodel.dart';
import 'all_reports_viewmodel.dart';

/// Layar daftar semua laporan untuk Admin.
class AllReportsScreen extends StatelessWidget {
  const AllReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AllReportsViewModel(
        reportRepository: context.read<ReportRepository>(),
      )..fetchAllReports(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin — Kelola Laporan'),
          // Fase 1: Diferensiasi UI (Admin menggunakan warna kontras)
          backgroundColor: const Color(0xFF1A237E), // Deep Navy
          foregroundColor: Colors.white,
          elevation: 0.5,
          actions: [
            Consumer<AllReportsViewModel>(
              builder: (context, vm, _) => IconButton(
                onPressed: vm.status == ViewStatus.loading ? null : vm.exportToCsv,
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
                  if (vm.status == ViewStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (vm.status == ViewStatus.failure) {
                    return Center(
                      child: Text(vm.error ?? 'Gagal mengambil data'),
                    );
                  }

                  final reports = vm.filteredReports;

                  if (reports.isEmpty) {
                    return const Center(child: Text('Tidak ada laporan ditemukan.'));
                  }

                  return RefreshIndicator(
                    onRefresh: vm.fetchAllReports,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: reports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      color: Colors.white,
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
                  borderRadius: BorderRadius.circular(12),
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
                FilterChip(
                  label: const Text('Semua'),
                  selected: vm.filterStatus == null,
                  onSelected: (_) => vm.setFilterStatus(null),
                ),
                const SizedBox(width: 8),
                ...ReportStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.label),
                      selected: vm.filterStatus == status,
                      onSelected: (_) => vm.setFilterStatus(status),
                    ),
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

class _ReportCard extends StatelessWidget {
  final Report report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AllReportsViewModel>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
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
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(report.title, style: AppTextStyles.subtitle),
            const SizedBox(height: 4),
            Text(report.address, style: AppTextStyles.caption),
            
            // Tampilkan alasan admin jika ada
            if (report.adminReason != null && report.adminReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Catatan Admin: ${report.adminReason}',
                  style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ubah Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                PopupMenuButton<ReportStatus>(
                  onSelected: (newStatus) => _handleStatusChange(context, vm, newStatus),
                  itemBuilder: (context) => ReportStatus.values.map((s) {
                    return PopupMenuItem(value: s, child: Text(s.label));
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E), // Admin theme color
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Text('Update', style: TextStyle(color: Colors.white, fontSize: 12)),
                        Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStatusChange(BuildContext context, AllReportsViewModel vm, ReportStatus newStatus) async {
    String? reason;
    
    // Fase 2: Alasan jika ditolak atau butuh keterangan tambahan
    if (newStatus == ReportStatus.rejected || newStatus == ReportStatus.inProgress) {
      reason = await showDialog<String>(
        context: context,
        builder: (context) => _ReasonDialog(status: newStatus),
      );
      if (reason == null) return; // User membatalkan dialog
    }

    final ok = await vm.updateStatus(report, newStatus, reason: reason);
    if (context.mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Gagal update status')),
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.status == ReportStatus.rejected ? 'Alasan Penolakan' : 'Catatan Proses'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Tulis keterangan di sini...'),
        maxLines: 3,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
