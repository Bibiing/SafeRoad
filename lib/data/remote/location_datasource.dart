import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

/// Hasil lokasi sederhana.
class LocationResult {
  final double latitude;
  final double longitude;
  const LocationResult({required this.latitude, required this.longitude});
}

/// Abstraksi data source lokasi (GPS + geocoding).
abstract class LocationDataSource {
  /// Ambil lokasi GPS saat ini.
  Future<LocationResult> getCurrentLocation();

  /// Reverse geocoding: koordinat → alamat teks.
  Future<String> getAddress(double latitude, double longitude);
}

/// Implementasi [LocationDataSource] menggunakan geolocator + geocoding.
class GeolocatorLocationDataSource implements LocationDataSource {
  @override
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
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LocationResult(latitude: pos.latitude, longitude: pos.longitude);
  }

  @override
  Future<String> getAddress(double latitude, double longitude) async {
    try {
      final placemarks =
          await geo.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return '';
      final p = placemarks.first;
      final parts = [
        p.street,
        p.subLocality,
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
        p.postalCode,
      ].where((s) => s != null && s.isNotEmpty);
      return parts.join(', ');
    } catch (_) {
      return '';
    }
  }
}
