import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/enums.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class CreateReportView extends StatefulWidget {
  const CreateReportView({super.key});

  @override
  State<CreateReportView> createState() => _CreateReportViewState();
}

class _CreateReportViewState extends State<CreateReportView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  ReportCategory _category = ReportCategory.lubang;
  File? _image;
  double? _latitude;
  double? _longitude;
  bool _locating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                AppStrings.pickPhotoTitle,
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text(AppStrings.camera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text(AppStrings.gallery),
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
        imageQuality: 70,
      );
      if (picked != null && mounted) {
        setState(() => _image = File(picked.path));
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showSnack(e.message ?? AppStrings.genericError);
    }
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    final result = await context.read<ReportViewModel>().fetchCurrentLocation();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (result != null) {
        _latitude = result.latitude;
        _longitude = result.longitude;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      _showSnack('Ambil lokasi terlebih dahulu.');
      return;
    }
    final uid = context.read<AuthViewModel>().currentUser?.uid;
    if (uid == null) return;

    final ok = await context.read<ReportViewModel>().submitReport(
      uid: uid,
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category,
      latitude: _latitude!,
      longitude: _longitude!,
      image: _image,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      _showSnack(
        context.read<ReportViewModel>().error ?? AppStrings.genericError,
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    final hasLocation = _latitude != null && _longitude != null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.newReport)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _titleController,
                  label: AppStrings.title,
                  validator: _required,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _descriptionController,
                  label: AppStrings.description,
                  maxLines: 4,
                  validator: _required,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.category,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<ReportCategory>(
                  initialValue: _category,
                  items: ReportCategory.values
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 16),
                _PhotoPicker(image: _image, onPick: _pickImage),
                const SizedBox(height: 16),
                _LocationRow(
                  hasLocation: hasLocation,
                  latitude: _latitude,
                  longitude: _longitude,
                  loading: _locating,
                  onTap: _getLocation,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: AppStrings.submit,
                  loading: vm.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    return null;
  }
}

class _PhotoPicker extends StatelessWidget {
  final File? image;
  final VoidCallback onPick;

  const _PhotoPicker({required this.image, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.photo, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: image != null
                ? Image.file(image!, fit: BoxFit.cover, width: double.infinity)
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 8),
                        Text(AppStrings.addPhoto, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  final bool hasLocation;
  final double? latitude;
  final double? longitude;
  final bool loading;
  final VoidCallback onTap;

  const _LocationRow({
    required this.hasLocation,
    required this.latitude,
    required this.longitude,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = hasLocation
        ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
        : AppStrings.useCurrentLocation;
    return OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      label: Text(text),
    );
  }
}
