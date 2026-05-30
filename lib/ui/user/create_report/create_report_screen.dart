import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import 'create_report_viewmodel.dart';

/// Layar buat laporan baru.
///
/// Form satu layar: foto, judul, deskripsi, kategori, lokasi GPS otomatis.
class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CreateReportViewModel(
        reportRepository: ctx.read<ReportRepository>(),
        authRepository: ctx.read<AuthRepository>(),
      ),
      child: const _CreateReportBody(),
    );
  }
}

class _CreateReportBody extends StatefulWidget {
  const _CreateReportBody();

  @override
  State<_CreateReportBody> createState() => _CreateReportBodyState();
}

class _CreateReportBodyState extends State<_CreateReportBody> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  ReportCategory _category = ReportCategory.pothole;
  File? _image;

  @override
  void initState() {
    super.initState();
    // Auto-fetch lokasi saat layar dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreateReportViewModel>().fetchCurrentLocation();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Pilih Sumber Foto', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Galeri'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: AppConstants.imageQuality,
      );
      if (picked != null && mounted) {
        setState(() => _image = File(picked.path));
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showSnack(e.message ?? 'Gagal memilih foto.');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<CreateReportViewModel>();
    final ok = await vm.submitReport(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
      images: _image != null ? [_image!] : [],
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      _showSnack(vm.error ?? 'Terjadi kesalahan.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateReportViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Foto ──
                _PhotoPicker(image: _image, onPick: _pickImage),
                const SizedBox(height: 20),

                // ── Judul ──
                Text('Judul', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Lubang besar di Jl. Merdeka',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // ── Deskripsi ──
                Text('Deskripsi', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan kondisi kerusakan...',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // ── Kategori ──
                Text('Kategori', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                DropdownButtonFormField<ReportCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(),
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
                const SizedBox(height: 20),

                // ── Lokasi ──
                _LocationSection(
                  hasLocation: vm.hasLocation,
                  latitude: vm.latitude,
                  longitude: vm.longitude,
                  address: vm.address,
                  loading: vm.isLocating,
                  onRefresh: () => vm.fetchCurrentLocation(),
                ),
                const SizedBox(height: 28),

                // ── Submit ──
                PrimaryButton(
                  label: 'Kirim Laporan',
                  loading: vm.isSubmitting,
                  icon: Icons.send,
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

/// Widget pemilih foto.
class _PhotoPicker extends StatelessWidget {
  final File? image;
  final VoidCallback onPick;

  const _PhotoPicker({required this.image, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Foto', style: AppTextStyles.subtitle),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                style: image == null ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: image != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(image!, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: AppColors.primary, size: 32),
                        SizedBox(height: 8),
                        Text('Tambah Foto',
                            style: TextStyle(color: AppColors.primary)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Widget informasi lokasi GPS.
class _LocationSection extends StatelessWidget {
  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final String address;
  final bool loading;
  final VoidCallback onRefresh;

  const _LocationSection({
    required this.hasLocation,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Lokasi', style: AppTextStyles.subtitle),
            const Spacer(),
            if (hasLocation)
              TextButton.icon(
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Perbarui'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasLocation ? AppColors.primaryTint : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: loading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Mendeteksi lokasi...'),
                  ],
                )
              : hasLocation
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address.isNotEmpty
                                    ? address
                                    : '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    )
                  : OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Gunakan Lokasi Saat Ini'),
                    ),
        ),
      ],
    );
  }
}
