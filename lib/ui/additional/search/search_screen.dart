import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/view_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import '../../user/report_detail/report_detail_screen.dart';
import 'search_viewmodel.dart';

/// Layar pencarian laporan berdasarkan kategori & kata kunci.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => SearchViewModel(
        reportRepository: ctx.read<ReportRepository>(),
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Pencarian Laporan')),
        body: Column(
          children: [
            const _SearchField(),
            const _CategoryFilter(),
            const Expanded(child: _SearchResults()),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SearchViewModel>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        autofocus: true,
        onChanged: vm.setQuery,
        decoration: const InputDecoration(
          hintText: 'Cari judul, alamat, atau deskripsi...',
          prefixIcon: Icon(Icons.search),
          isDense: true,
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Semua'),
              selected: vm.category == null,
              onSelected: (_) => vm.setCategory(null),
            ),
          ),
          ...ReportCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category.label),
                selected: vm.category == category,
                onSelected: (_) => vm.setCategory(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const LoadingIndicator(message: 'Memuat data...');
        }
        if (vm.status == ViewStatus.failure) {
          return ErrorState(
            message: vm.error ?? 'Gagal memuat data.',
            onRetry: vm.load,
          );
        }

        final results = vm.results;
        if (results.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'Tidak ada hasil.',
            subtitle: 'Coba ubah kata kunci atau kategori.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final report = results[index];
            return _SearchResultTile(
              report: report,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportDetailScreen(reportId: report.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _SearchResultTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
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
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.address,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            DateFormatter.relative(report.createdAt),
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
