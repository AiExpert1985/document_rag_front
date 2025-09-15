// src/api_service.dart - ONLY change the baseUrl

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class ApiService {
  // Fix: Try localhost first, then your IP
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000/', // CHANGED: Try localhost first
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<List<Map<String, dynamic>>> listDocuments() async {
    final response = await _dio.get('/documents');
    return List<Map<String, dynamic>>.from(response.data['documents']);
  }

  Future<void> deleteDocument(String docId) async {
    await _dio.delete('/documents/$docId');
  }

  Future<Map<String, dynamic>> uploadDocument(PlatformFile file) async {
    // Handle both web (bytes) and mobile (path) platforms
    MultipartFile multipartFile;
    
    if (file.bytes != null) {
      // Web platform
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    } else if (file.path != null) {
      // Mobile platform  
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    } else {
      throw Exception('Cannot read file');
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    final response = await _dio.post('/upload-pdf', data: formData);
    return response.data;
  }
  
  Future<List<dynamic>> search(String query) async {
    final response = await _dio.post('/search', data: {'question': query});
    return response.data['results'];
  }
}