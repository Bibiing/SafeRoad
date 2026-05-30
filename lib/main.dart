import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/report_repository.dart';
import 'services/storage_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/report_viewmodel.dart';
import 'views/auth/login_view.dart';
import 'views/user/user_home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id');
  runApp(const SafeRoadApp());
}

class SafeRoadApp extends StatelessWidget {
  const SafeRoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authService)),
        ChangeNotifierProvider(
          create: (_) => ReportViewModel(
            ReportRepository(),
            StorageService(),
            LocationService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Tentukan layar awal berdasarkan status login Firebase.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();
    return StreamBuilder(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != null) {
          // Pastikan profil termuat sebelum masuk home.
          // Defer ke frame berikutnya agar tidak memanggil notifyListeners
          // di tengah build phase, yang menyebabkan setState-during-build crash.
          if (authVm.currentUser == null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => authVm.loadCurrentUser());
          }
          return const UserHomeView();
        }
        return const LoginView();
      },
    );
  }
}
