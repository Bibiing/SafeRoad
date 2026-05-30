import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/report_model.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../widgets/status_badge.dart';

class ReportDetailView extends StatelessWidget {
  final ReportModel report;

  const ReportDetailView({super.key, required this.report});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.delete),
        content: const Text(
          'Hapus laporan ini? Tindakan tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final vm = context.read<ReportViewModel>();
    final ok = await vm.deleteReport(report);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? AppStrings.genericError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = report.createdAt;
    final dateText = date != null
        ? DateFormat('d MMMM yyyy, HH:mm', 'id').format(date)
        : '-';
    final photoUrl = report.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reportDetail),
        actions: [
          IconButton(
            tooltip: AppStrings.delete,
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (photoUrl != null && photoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text(report.title, style: AppTextStyles.heading)),
              StatusBadge(status: report.status),
            ],
          ),
          const SizedBox(height: 8),
          _Field(label: AppStrings.category, value: report.category.label),
          _Field(label: AppStrings.description, value: report.description),
          _Field(
            label: AppStrings.location,
            value:
                '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}'
                '${report.address.isNotEmpty ? '\n${report.address}' : ''}',
          ),
          _Field(label: 'Dibuat', value: dateText),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.body),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}
