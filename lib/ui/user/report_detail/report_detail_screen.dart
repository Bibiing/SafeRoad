import 'package:saferoad/core/theme/app_colors_extension.dart';
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
          // 隨渉隨渉 Foto (slideshow + full screen) 隨渉隨渉
          if (report.imageUrls.isNotEmpty) ...[
            _PhotoSlideshow(imageUrls: report.imageUrls),
            const SizedBox(height: 16),
          ],

          // 隨渉隨渉 Judul + Status 隨渉隨渉
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

          // 隨渉隨渉 Field Info 隨渉隨渉
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

          // 隨渉隨渉 Timeline Status 隨渉隨渉
          const SizedBox(height: 24),
          Text('Riwayat Status', style: AppTextStyles.title),
          const SizedBox(height: 12),
          if (vm.statusLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appColors.primaryTint,
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
              // 隨渉隨渉 Dot + Line 隨渉隨渉
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
                          color: context.appColors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 隨渉隨渉 Content 隨渉隨渉
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
                            color: context.appColors.textPrimary,
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

/// Slideshow foto laporan: [PageView] horizontal yang bisa diswipe, dengan
/// indikator "x/total" dan dot indicator. Tap foto 遶翫・galeri full screen.
class _PhotoSlideshow extends StatefulWidget {
  final List<String> imageUrls;

  const _PhotoSlideshow({required this.imageUrls});

  @override
  State<_PhotoSlideshow> createState() => _PhotoSlideshowState();
}

class _PhotoSlideshowState extends State<_PhotoSlideshow> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => _FullscreenGallery(
          imageUrls: widget.imageUrls,
          initialIndex: index,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    final multiple = urls.length > 1;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => _openFullscreen(i),
                    child: Image.network(
                      urls[i],
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: context.appColors.primaryTint,
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        color: context.appColors.primaryTint,
                        child: Icon(Icons.broken_image,
                            size: 48, color: context.appColors.textHint),
                      ),
                    ),
                  ),
                ),
                if (multiple)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _PhotoCounterBadge(
                      current: _index + 1,
                      total: urls.length,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (multiple) ...[
          const SizedBox(height: 10),
          _DotsIndicator(count: urls.length, activeIndex: _index),
        ],
      ],
    );
  }
}

/// Badge "x/total" putih di atas latar gelap transparan.
class _PhotoCounterBadge extends StatelessWidget {
  final int current;
  final int total;

  const _PhotoCounterBadge({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$current/$total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Dot indicator di bawah slideshow; dot aktif memanjang berwarna primer.
class _DotsIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const _DotsIndicator({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : context.appColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Galeri foto full screen: pinch-to-zoom ([InteractiveViewer]) + swipe
/// ([PageView]) antar foto, dibuka pada indeks yang di-tap.
class _FullscreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullscreenGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  urls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: _PhotoCounterBadge(
                      current: _index + 1,
                      total: urls.length,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
