import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Abstraksi data source penyimpanan file (Firebase Storage).
abstract class StorageRemoteDataSource {
  /// Upload satu file, kembalikan URL unduh.
  Future<String> uploadFile({
    required String path,
    required File file,
  });

  /// Hapus file berdasarkan URL unduh. Diabaikan bila tidak ada.
  Future<void> deleteByUrl(String url);
}

/// Implementasi [StorageRemoteDataSource] menggunakan Firebase Storage.
class FirebaseStorageRemoteDataSource implements StorageRemoteDataSource {
  final FirebaseStorage _storage;

  FirebaseStorageRemoteDataSource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadFile({
    required String path,
    required File file,
  }) async {
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  @override
  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException {
      // Objek mungkin sudah terhapus — abaikan.
    }
  }
}
