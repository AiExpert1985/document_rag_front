// lib/src/api_service.dart - No changes needed from your current version
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import 'package:document_chat/src/models/document.dart';
import 'package:document_chat/src/models/search_result.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'http://127.0.0.1:8000',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
        ));

  // --- FIX #7: IMPROVED DIO ERROR HANDLING WITH ERROR CODES ---
  Never _handleDioError(DioException e) {
    final errorCode = e.response?.statusCode ?? 0;

    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      final detail = e.response?.data['detail'];
      throw ApiException('[$errorCode] $detail');
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiException('[$errorCode] Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        throw ApiException('[$errorCode] Could not connect to server. Check network.');
      default:
        throw ApiException('[$errorCode] Unexpected error occurred.');
    }
  }
  // -------------------------------------------------------------

  Future<List<Document>> listDocuments() async {
    try {
      final response = await _dio.get('/documents');
      final List<dynamic> docList = response.data['documents'];
      return docList.map((json) => Document.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> deleteDocument(String docId) async {
    try {
      await _dio.delete('/documents/$docId');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> clearAllDocuments() async {
    try {
      await _dio.delete('/documents');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> uploadDocument(PlatformFile file) async {
    MultipartFile multipartFile;
    if (file.bytes != null) {
      multipartFile = MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else if (file.path != null) {
      multipartFile = await MultipartFile.fromFile(file.path!, filename: file.name);
    } else {
      throw ApiException('Cannot read the selected file.');
    }

    final formData = FormData.fromMap({'file': multipartFile});

    try {
      final response = await _dio.post('/upload-document', data: formData);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<List<SearchResult>> search(String query) async {
    try {
      final response = await _dio.post('/search', data: {'question': query});
      final List<dynamic> results = response.data['results'];
      return results.map((json) => SearchResult.fromJson(json)).toList();
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    try {
      final response = await _dio.get('/search-history');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> clearChatHistory() async {
    try {
      await _dio.delete('/search-history');
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }
}
