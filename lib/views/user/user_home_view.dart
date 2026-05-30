import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import '../widgets/report_card.dart';

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final uid = context.read<AuthViewModel>().currentUser?.uid;
    if (uid != null) {
      context.read<ReportViewModel>().loadMyReports(uid);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myReports),
        actions: [
          IconButton(
            tooltip: AppStrings.logout,
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).pushNamed(AppRoutes.createReport);
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newReport),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: _buildBody(vm),
      ),
    );
  }

  Widget _buildBody(ReportViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return _Message(text: vm.error!, onRetry: _load);
    }
    if (vm.myReports.isEmpty) {
      return const _Message(text: AppStrings.emptyReports);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vm.myReports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = vm.myReports[index];
        return ReportCard(
          report: report,
          onTap: () async {
            await Navigator.of(
              context,
            ).pushNamed(AppRoutes.reportDetail, arguments: report);
            _load();
          },
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                text,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
