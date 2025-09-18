// src/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:document_chat/src/api_service.dart';
// CHANGED: Import models
import 'package:document_chat/src/models/document.dart';
import 'package:document_chat/src/models/chat_message.dart';

// Provides the API service instance
final apiServiceProvider = Provider((ref) => ApiService());

// Manages the list of documents for the admin screen
// CHANGED: Provider now returns a list of Document objects
final documentsProvider = FutureProvider<List<Document>>((ref) async {
  return ref.watch(apiServiceProvider).listDocuments();
});

// Manages chat messages
// CHANGED: State is now a list of ChatMessage objects
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref.watch(apiServiceProvider));
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ApiService _apiService;

  ChatNotifier(this._apiService) : super([]);

  Future<void> sendMessage(String message) async {
    // Add user message to state
    state = [...state, ChatMessage(sender: Sender.user, text: message)];

    try {
      final results = await _apiService.search(message);
      if (results.isEmpty) {
        state = [...state, ChatMessage(sender: Sender.ai, error: 'No relevant information found.')];
      } else {
        // Add each search result as a separate AI message
        final aiMessages =
            results.map((result) => ChatMessage(sender: Sender.ai, searchResult: result));
        state = [...state, ...aiMessages];
      }
    } on ApiException catch (e) {
      state = [...state, ChatMessage(sender: Sender.ai, error: 'Error: $e')];
    }
  }
}
