import 'package:flutter/foundation.dart';

import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import '../../../core/state/view_status.dart';
import '../../../core/utils/error_mapper.dart';

/// ViewModel untuk layar edit laporan.
class EditReportViewModel extends ChangeNotifier {
  final ReportRepository _reportRepository;

  EditReportViewModel(this._reportRepository);

  ViewStatus _status = ViewStatus.initial;
  ViewStatus get status => _status;

  bool get isLoading => _status == ViewStatus.loading;

  String? _error;
  String? get error => _error;

  bool get isSubmitting => _status == ViewStatus.loading;

  /// Update laporan yang sudah ada.
  Future<bool> updateReport({
    required Report original,
    required String title,
    required String description,
    required ReportCategory category,
  }) async {
    _status = ViewStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final updated = original.copyWith(
        title: title.trim(),
        description: description.trim(),
        category: category,
        updatedAt: DateTime.now(),
      );
      await _reportRepository.updateReport(updated);
      _status = ViewStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _error = mapErrorToMessage(e);
      _status = ViewStatus.failure;
      notifyListeners();
      return false;
    }
  }

}
