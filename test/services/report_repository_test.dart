import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saferoad/models/enums.dart';
import 'package:saferoad/models/report_model.dart';
import 'package:saferoad/services/report_repository.dart';

ReportModel _sample({
  required String userId,
  String title = 'Lubang besar',
  ReportStatus status = ReportStatus.pending,
}) {
  return ReportModel(
    id: '',
    userId: userId,
    title: title,
    description: 'Deskripsi',
    category: ReportCategory.lubang,
    status: status,
    latitude: -7.25,
    longitude: 112.75,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late ReportRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ReportRepository(firestore: firestore);
  });

  test('createReport menulis dokumen ke koleksi reports', () async {
    final id = await repo.createReport(_sample(userId: 'u1'));

    final doc = await firestore.collection('reports').doc(id).get();
    expect(doc.exists, isTrue);
    expect(doc.data()!['userId'], 'u1');
    expect(doc.data()!['title'], 'Lubang besar');
    expect(doc.data()!['status'], ReportStatus.pending.value);
  });

  test('getReportsByUser hanya mengembalikan laporan milik uid', () async {
    await repo.createReport(_sample(userId: 'u1', title: 'A'));
    await repo.createReport(_sample(userId: 'u1', title: 'B'));
    await repo.createReport(_sample(userId: 'u2', title: 'C'));

    final mine = await repo.getReportsByUser('u1');
    expect(mine, hasLength(2));
    expect(mine.every((r) => r.userId == 'u1'), isTrue);
  });

  test('updateStatus mengubah field status', () async {
    final id = await repo.createReport(_sample(userId: 'u1'));

    await repo.updateStatus(id, ReportStatus.selesai);

    final updated = await repo.getReportById(id);
    expect(updated, isNotNull);
    expect(updated!.status, ReportStatus.selesai);
  });

  test('deleteReport menghapus dokumen', () async {
    final id = await repo.createReport(_sample(userId: 'u1'));

    await repo.deleteReport(id);

    final doc = await firestore.collection('reports').doc(id).get();
    expect(doc.exists, isFalse);
  });

  test('getReportById mengembalikan null bila dokumen tidak ada', () async {
    final result = await repo.getReportById('tidak-ada');
    expect(result, isNull);
  });
}
