import 'package:geolocator/geolocator.dart';

/// Hasil lokasi sederhana — dipisah dari tipe geolocator agar mudah dipakai
/// ViewModel/Model dan di-mock saat test.
class LocationResult {
  final double latitude;
  final double longitude;

  const LocationResult({required this.latitude, required this.longitude});
}

/// Akses GPS perangkat. Menangani permission & layanan lokasi.
class LocationService {
  /// Ambil lokasi saat ini. Lempar [Exception] dengan pesan jelas bila gagal.
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi tidak aktif. Aktifkan GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Izin lokasi ditolak.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Ubah di pengaturan.');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LocationResult(latitude: pos.latitude, longitude: pos.longitude);
  }
}
