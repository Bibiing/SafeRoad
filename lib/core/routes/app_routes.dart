import 'package:flutter/material.dart';

import '../../models/report_model.dart';
import '../../views/auth/login_view.dart';
import '../../views/auth/register_view.dart';
import '../../views/user/create_report_view.dart';
import '../../views/user/report_detail_view.dart';
import '../../views/user/user_home_view.dart';

/// Nama rute & generator. View detail menerima [ReportModel] lewat arguments.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String userHome = '/user/home';
  static const String createReport = '/user/report/create';
  static const String reportDetail = '/user/report/detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _page(const LoginView(), settings);
      case register:
        return _page(const RegisterView(), settings);
      case userHome:
        return _page(const UserHomeView(), settings);
      case createReport:
        return _page(const CreateReportView(), settings);
      case reportDetail:
        final report = settings.arguments as ReportModel;
        return _page(ReportDetailView(report: report), settings);
      default:
        return _page(const LoginView(), settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => child,
      settings: settings,
    );
  }
}
