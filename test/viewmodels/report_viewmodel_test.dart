import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saferoad/models/enums.dart';
import 'package:saferoad/models/report_model.dart';
import 'package:saferoad/services/location_service.dart';
import 'package:saferoad/services/report_repository.dart';
import 'package:saferoad/services/storage_service.dart';
import 'package:saferoad/viewmodels/report_viewmodel.dart';

class MockReportRepository extends Mock implements ReportRepository {}

class MockStorageService extends Mock implements StorageService {}

class MockLocationService extends Mock implements LocationService {}

ReportModel _report(String id, {String? photoUrl}) {
  return ReportModel(
    id: id,
    userId: 'u1',
    title: 'Lubang $id',
    description: 'd',
    category: ReportCategory.lubang,
    latitude: 1,
    longitude: 2,
    photoUrl: photoUrl,
  );
}

void main() {
  late MockReportRepository repo;
  late MockStorageService storage;
  late MockLocationService location;
  late ReportViewModel vm;

  setUpAll(() {
    registerFallbackValue(_report('fallback'));
    registerFallbackValue(File('fallback'));
  });

  setUp(() {
    repo = MockReportRepository();
    storage = MockStorageService();
    location = MockLocationService();
    vm = ReportViewModel(repo, storage, location);
  });

  group('loadMyReports', () {
    test('sukses mengisi daftar dan mematikan loading', () async {
      when(
        () => repo.getReportsByUser('u1'),
      ).thenAnswer((_) async => [_report('1'), _report('2')]);

      await vm.loadMyReports('u1');

      expect(vm.myReports, hasLength(2));
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
    });

    test('gagal mengisi error', () async {
      when(
        () => repo.getReportsByUser('u1'),
      ).thenThrow(Exception('gagal memuat'));

      await vm.loadMyReports('u1');

      expect(vm.error, 'gagal memuat');
      expect(vm.isLoading, isFalse);
    });
  });

  group('submitReport', () {
    test('tanpa foto memanggil createReport lalu refresh daftar', () async {
      when(() => repo.createReport(any())).thenAnswer((_) async => 'id1');
      when(
        () => repo.getReportsByUser('u1'),
      ).thenAnswer((_) async => [_report('id1')]);

      final ok = await vm.submitReport(
        uid: 'u1',
        title: 'Lubang',
        description: 'd',
        category: ReportCategory.lubang,
        latitude: 1,
        longitude: 2,
      );

      expect(ok, isTrue);
      verify(() => repo.createReport(any())).called(1);
      verifyNever(
        () => storage.uploadReportImage(
          userId: any(named: 'userId'),
          file: any(named: 'file'),
        ),
      );
      expect(vm.myReports, hasLength(1));
    });

    test('dengan foto mengunggah dulu lalu createReport', () async {
      when(
        () => storage.uploadReportImage(
          userId: any(named: 'userId'),
          file: any(named: 'file'),
        ),
      ).thenAnswer((_) async => 'https://foto/1.jpg');
      when(() => repo.createReport(any())).thenAnswer((_) async => 'id1');
      when(() => repo.getReportsByUser('u1')).thenAnswer((_) async => []);

      final ok = await vm.submitReport(
        uid: 'u1',
        title: 'Lubang',
        description: 'd',
        category: ReportCategory.lubang,
        latitude: 1,
        longitude: 2,
        image: File('foto.jpg'),
      );

      expect(ok, isTrue);
      verify(
        () => storage.uploadReportImage(
          userId: 'u1',
          file: any(named: 'file'),
        ),
      ).called(1);
    });

    test('gagal createReport mengisi error dan return false', () async {
      when(() => repo.createReport(any())).thenThrow(Exception('gagal simpan'));

      final ok = await vm.submitReport(
        uid: 'u1',
        title: 'Lubang',
        description: 'd',
        category: ReportCategory.lubang,
        latitude: 1,
        longitude: 2,
      );

      expect(ok, isFalse);
      expect(vm.error, 'gagal simpan');
      expect(vm.isSubmitting, isFalse);
    });
  });

  group('fetchCurrentLocation', () {
    test('sukses mengembalikan lokasi', () async {
      when(() => location.getCurrentLocation()).thenAnswer(
        (_) async => const LocationResult(latitude: 1.5, longitude: 2.5),
      );

      final result = await vm.fetchCurrentLocation();

      expect(result, isNotNull);
      expect(result!.latitude, 1.5);
    });

    test('gagal mengembalikan null dan mengisi error', () async {
      when(
        () => location.getCurrentLocation(),
      ).thenThrow(Exception('Izin lokasi ditolak.'));

      final result = await vm.fetchCurrentLocation();

      expect(result, isNull);
      expect(vm.error, 'Izin lokasi ditolak.');
    });
  });

  group('deleteReport', () {
    test('menghapus laporan dari daftar', () async {
      when(
        () => repo.getReportsByUser('u1'),
      ).thenAnswer((_) async => [_report('1'), _report('2')]);
      await vm.loadMyReports('u1');

      when(() => repo.deleteReport('1')).thenAnswer((_) async {});

      final ok = await vm.deleteReport(_report('1'));

      expect(ok, isTrue);
      expect(vm.myReports, hasLength(1));
      expect(vm.myReports.first.id, '2');
    });

    test('menghapus foto bila ada photoUrl', () async {
      when(() => repo.deleteReport('1')).thenAnswer((_) async {});
      when(() => storage.deleteByUrl(any())).thenAnswer((_) async {});

      final ok = await vm.deleteReport(
        _report('1', photoUrl: 'https://foto/1.jpg'),
      );

      expect(ok, isTrue);
      verify(() => storage.deleteByUrl('https://foto/1.jpg')).called(1);
    });
  });
}
