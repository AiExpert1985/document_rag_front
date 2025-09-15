// src/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:document_chat/src/api_service.dart';

// Provides the API service instance
final apiServiceProvider = Provider((ref) => ApiService());

// Manages the list of documents for the admin screen
final documentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(apiServiceProvider).listDocuments();
});

// Manages chat messages
final chatProvider = StateNotifierProvider<ChatNotifier, List<Map<String, dynamic>>>((ref) {
  return ChatNotifier(ref.watch(apiServiceProvider));
});

class ChatNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final ApiService _apiService;
  
  ChatNotifier(this._apiService) : super([]);

  Future<void> sendMessage(String message) async {
    state = [...state, {'sender': 'user', 'content': message}];
    try {
      final results = await _apiService.search(message);
      if (results.isEmpty) {
        state = [...state, {'sender': 'ai', 'content': 'No relevant information found.'}];
      } else {
        for (var result in results) {
          state = [...state, {'sender': 'ai', 'content': result}];
        }
      }
    } catch (e) {
      state = [...state, {'sender': 'ai', 'content': 'Error: Could not get response.'}];
    }
  }
}