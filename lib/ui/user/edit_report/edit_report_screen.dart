import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import 'edit_report_viewmodel.dart';

/// Layar edit laporan — pre-filled, hanya untuk laporan berstatus pending.
class EditReportScreen extends StatelessWidget {
  final Report report;

  const EditReportScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => EditReportViewModel(ctx.read<ReportRepository>()),
      child: _EditBody(report: report),
    );
  }
}

class _EditBody extends StatefulWidget {
  final Report report;

  const _EditBody({required this.report});

  @override
  State<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends State<_EditBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late ReportCategory _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.report.title);
    _descriptionController =
        TextEditingController(text: widget.report.description);
    _category = widget.report.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<EditReportViewModel>();
    final ok = await vm.updateReport(
      original: widget.report,
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Gagal menyimpan perubahan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditReportViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Laporan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Judul', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                Text('Deskripsi', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                Text('Kategori', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                DropdownButtonFormField<ReportCategory>(
                  initialValue: _category,
                  items: ReportCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Simpan Perubahan',
                  loading: vm.isSubmitting,
                  icon: Icons.save,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
