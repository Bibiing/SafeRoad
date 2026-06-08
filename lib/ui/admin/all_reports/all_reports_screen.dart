import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/view_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
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

            // ── Galeri foto dari pelapor ──
            if (report.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.imageUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () => _showImageViewer(context, report.imageUrls, i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          report.imageUrls[i],
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 90,
                              height: 90,
                              color: AppColors.background,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => Container(
                            width: 90,
                            height: 90,
                            color: AppColors.background,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

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
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: InkWell(
                onTap: () => _openStatusSheet(context, vm),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ubah Status', style: AppTextStyles.button),
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
            ),
          ],
        ),
      ),
    );
  }

  void _showImageViewer(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      builder: (context) => _ImageViewerDialog(
        urls: urls,
        initialIndex: initialIndex,
      ),
    );
  }

  Future<void> _openStatusSheet(
    BuildContext context,
    AllReportsViewModel vm,
  ) async {
    final result = await showModalBottomSheet<_StatusChangeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StatusChangeSheet(report: report),
    );
    if (result == null) return;

    final ok = await vm.updateStatus(
      report,
      result.status,
      reason: result.reason,
    );
    if (context.mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Gagal memperbarui status')),
      );
    }
  }
}

/// Hasil pemilihan status dari [_StatusChangeSheet].
class _StatusChangeResult {
  final ReportStatus status;
  final String? reason;

  const _StatusChangeResult(this.status, this.reason);
}

/// Bottom sheet "Ubah Status Laporan" — konsisten dengan sistem hijau SafeRoad.
///
/// Menampilkan pilihan status (pending dikecualikan) sebagai daftar [ListTile]
/// dengan [StatusPill]. Bila `rejected` dipilih, alasan penolakan wajib diisi.
class _StatusChangeSheet extends StatefulWidget {
  final Report report;

  const _StatusChangeSheet({required this.report});

  @override
  State<_StatusChangeSheet> createState() => _StatusChangeSheetState();
}

class _StatusChangeSheetState extends State<_StatusChangeSheet> {
  // Admin tidak mengembalikan laporan ke pending → dikecualikan dari pilihan.
  static const _options = [
    ReportStatus.verified,
    ReportStatus.inProgress,
    ReportStatus.completed,
    ReportStatus.rejected,
  ];

  ReportStatus? _selected;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_selected == null) return false;
    // Alasan wajib diisi saat menolak laporan.
    if (_selected == ReportStatus.rejected) {
      return _reasonController.text.trim().isNotEmpty;
    }
    return true;
  }

  void _confirm() {
    final selected = _selected;
    if (selected == null) return;
    final reason = _reasonController.text.trim();
    Navigator.of(context).pop(
      _StatusChangeResult(selected, reason.isEmpty ? null : reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _selected == ReportStatus.rejected;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Ubah Status Laporan', style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(
              widget.report.title,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ..._options.map((s) {
              final selected = _selected == s;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: selected ? AppColors.primaryTint : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    onTap: () => setState(() => _selected = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppTheme.radius),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          StatusPill(status: s),
                          const Spacer(),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (isRejected) ...[
              const SizedBox(height: 8),
              Text('Alasan Penolakan', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Wajib diisi: jelaskan alasan penolakan...',
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Simpan',
              onPressed: _canSave ? _confirm : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog fullscreen viewer untuk foto laporan dengan swipe horizontal.
class _ImageViewerDialog extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _ImageViewerDialog({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
              ),
            ),
          ),
          if (widget.urls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${_currentIndex + 1} / ${widget.urls.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

