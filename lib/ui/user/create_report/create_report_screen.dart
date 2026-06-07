import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/category_helper.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../domain/repository/report_repository.dart';
import 'create_report_viewmodel.dart';

/// Layar buat laporan baru — satu layar scroll dengan indikator progres.
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
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  ReportCategory _category = ReportCategory.pothole;
  final List<File> _images = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreateReportViewModel>().fetchCurrentLocation();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Jumlah langkah yang sudah terpenuhi (untuk indikator progres).
  int _completedSteps(CreateReportViewModel vm) {
    var done = 1; // kategori selalu terisi (default).
    if (_images.isNotEmpty) done++;
    if (vm.hasLocation) done++;
    if (_descriptionController.text.trim().isNotEmpty) done++;
    return done;
  }

  Future<void> _pickImage() async {
    if (_images.length >= AppConstants.maxReportPhotos) {
      _showSnack('Maksimal ${AppConstants.maxReportPhotos} foto.');
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
        setState(() => _images.add(File(picked.path)));
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showSnack(e.message ?? 'Gagal memilih foto.');
    }
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  /// Bentuk judul otomatis dari kategori + potongan alamat (form tanpa field
  /// judul, sesuai desain acuan).
  String _composeTitle(CreateReportViewModel vm) {
    final addr = vm.address.trim();
    if (addr.isEmpty) return _category.label;
    final shortAddr = addr.split(',').first.trim();
    return shortAddr.isEmpty ? _category.label : '${_category.label} di $shortAddr';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<CreateReportViewModel>();
    final ok = await vm.submitReport(
      title: _composeTitle(vm),
      description: _descriptionController.text,
      category: _category,
      images: _images,
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
      appBar: AppBar(title: const Text('Buat Laporan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepProgress(completed: _completedSteps(vm), total: 4),
                const SizedBox(height: 24),

                // ── 1. Kategori ──
                _SectionLabel(number: 1, text: 'Apa yang ingin Anda laporkan?'),
                const SizedBox(height: 12),
                _CategoryGrid(
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 24),

                // ── 2. Foto ──
                _SectionLabel(number: 2, text: 'Unggah Foto'),
                const SizedBox(height: 12),
                _PhotoPicker(
                  images: _images,
                  max: AppConstants.maxReportPhotos,
                  onAdd: _pickImage,
                  onRemove: _removeImage,
                ),
                const SizedBox(height: 24),

                // ── 3. Lokasi ──
                _SectionLabel(number: 3, text: 'Lokasi'),
                const SizedBox(height: 12),
                _LocationSection(
                  hasLocation: vm.hasLocation,
                  latitude: vm.latitude,
                  longitude: vm.longitude,
                  address: vm.address,
                  loading: vm.isLocating,
                  onChange: () => vm.fetchCurrentLocation(),
                ),
                const SizedBox(height: 24),

                // ── 4. Deskripsi ──
                _SectionLabel(number: 4, text: 'Deskripsi'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan detail laporan di sini...',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),

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

/// Indikator progres 4 segmen.
class _StepProgress extends StatelessWidget {
  final int completed;
  final int total;

  const _StepProgress({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final shown = completed.clamp(1, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Langkah $shown dari $total', style: AppTextStyles.subtitle),
        const SizedBox(height: 8),
        Row(
          children: List.generate(total, (i) {
            final active = i < completed;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final int number;
  final String text;

  const _SectionLabel({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$number. ', style: AppTextStyles.title),
        Expanded(child: Text(text, style: AppTextStyles.title)),
      ],
    );
  }
}

/// Grid pemilih kategori (ikon + label).
class _CategoryGrid extends StatelessWidget {
  final ReportCategory selected;
  final ValueChanged<ReportCategory> onSelected;

  const _CategoryGrid({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: ReportCategory.values.map((c) {
        final active = c == selected;
        return InkWell(
          onTap: () => onSelected(c),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: active ? AppColors.primaryTint : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CategoryHelper.iconOf(c),
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    c.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color:
                          active ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Area unggah foto (maks N) + thumbnail dengan tombol hapus.
class _PhotoPicker extends StatelessWidget {
  final List<File> images;
  final int max;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _PhotoPicker({
    required this.images,
    required this.max,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = images.length >= max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFull)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryTint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      color: AppColors.primary, size: 30),
                  const SizedBox(height: 8),
                  Text('Tap untuk unggah foto', style: AppTextStyles.subtitle),
                  const SizedBox(height: 2),
                  Text(
                    max == 1 ? 'Hanya 1 foto' : 'Maksimal $max foto',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        if (images.isNotEmpty) ...[
          if (!isFull) const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(images.length, (i) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      images[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Bagian lokasi: preview peta kecil + alamat + tombol ubah.
class _LocationSection extends StatelessWidget {
  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final String address;
  final bool loading;
  final VoidCallback onChange;

  const _LocationSection({
    required this.hasLocation,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.loading,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 12),
            Text('Mendeteksi lokasi...'),
          ],
        ),
      );
    }

    if (!hasLocation) {
      return OutlinedButton.icon(
        onPressed: onChange,
        icon: const Icon(Icons.my_location),
        label: const Text('Gunakan Lokasi Saat Ini'),
      );
    }

    final lat = latitude!, lng = longitude!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 140,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(lat, lng),
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: LatLng(lat, lng),
                ),
              },
              zoomGesturesEnabled: false,
              scrollGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                address.isNotEmpty
                    ? address
                    : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                style: AppTextStyles.body.copyWith(fontSize: 14),
              ),
            ),
            TextButton.icon(
              onPressed: onChange,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
              label: const Text('Ubah'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }
}
