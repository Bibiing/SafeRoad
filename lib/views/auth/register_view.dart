import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final ok = await vm.register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.userHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.register)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: AppStrings.name,
                  validator: _required,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  obscureText: true,
                  validator: _validatePassword,
                ),
                if (vm.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    vm.error!,
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: AppStrings.register,
                  loading: vm.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: vm.isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.haveAccount),
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

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.requiredField;
    if (!value.contains('@')) return AppStrings.invalidEmail;
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.requiredField;
    if (value.length < 6) return AppStrings.shortPassword;
    return null;
  }
}
