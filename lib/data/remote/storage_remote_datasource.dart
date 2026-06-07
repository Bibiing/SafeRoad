import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

/// Abstraksi data source penyimpanan file.
abstract class StorageRemoteDataSource {
  /// Upload satu file, kembalikan URL unduh.
  Future<String> uploadFile({
    required String path,
    required File file,
  });

  /// Hapus file berdasarkan URL unduh. Diabaikan bila tidak ada.
  Future<void> deleteByUrl(String url);
}

/// Implementasi [StorageRemoteDataSource] menggunakan ImageKit.
class ImageKitStorageRemoteDataSource implements StorageRemoteDataSource {
  final Dio _dio;

  // PERINGATAN KEAMANAN: Hardcoding private key tidak disarankan untuk aplikasi produksi.
  static const String _imagekitPrivate = 'private_NtsRjvnsMvPyBC0fM0iw2oWEcyA=';

  ImageKitStorageRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<String> uploadFile({
    required String path,
    required File file,
  }) async {
    // ImageKit menggunakan Basic Auth dengan Private Key sebagai username dan password kosong.
    final String auth = 'Basic ${base64Encode(utf8.encode('$_imagekitPrivate:'))}';

    // Ekstrak nama file dan folder dari path.
    // Contoh path: 'reports/userId/123.jpg'
    final fileName = path.split('/').last;
    final folder = '/saferoad/${path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : ''}';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'fileName': fileName,
      'folder': folder,
      'useUniqueFileName': 'true',
    });

    try {
      final response = await _dio.post(
        'https://upload.imagekit.io/api/v1/files/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': auth,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['url'] as String;
      } else {
        throw Exception('Gagal upload ke ImageKit: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final message = errorData is Map ? errorData['message'] : e.message;
      throw Exception('Error ImageKit: $message');
    }
  }

  @override
  Future<void> deleteByUrl(String url) async {
    // Diabaikan sesuai rencana "simpan beberapa data saja".
  }
}