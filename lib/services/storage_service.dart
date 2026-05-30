import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Upload/hapus foto laporan di Firebase Storage.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Upload foto ke `reports/{userId}/{timestamp}.jpg`, kembalikan URL unduh.
  Future<String> uploadReportImage({
    required String userId,
    required File file,
  }) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('reports').child(userId).child(name);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  /// Hapus objek berdasarkan URL unduh. Diabaikan bila objek tidak ada.
  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException {
      // Objek mungkin sudah terhapus — abaikan.
    }
  }
}
