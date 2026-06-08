import 'package:connectivity_plus/connectivity_plus.dart';

/// Pemantau status koneksi perangkat berbasis `connectivity_plus`.
///
/// Bersih dan reusable — tidak bergantung pada widget/UI. Mengekspos status
/// sebagai `bool` (true = online, false = offline).
///
/// Catatan: `connectivity_plus` mendeteksi adanya jaringan (wifi/seluler/dll),
/// bukan akses internet sebenarnya. Untuk kebutuhan peringatan offline ini
/// sudah memadai tanpa perlu ping ke server.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// True bila ada minimal satu koneksi aktif (bukan `none`).
  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  /// Stream status koneksi: emit `true` saat online, `false` saat offline.
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  /// Cek status koneksi saat ini (mis. saat app baru dibuka).
  Future<bool> isOnline() async =>
      _isOnline(await _connectivity.checkConnectivity());
}
