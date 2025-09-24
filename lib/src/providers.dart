// lib/src/providers.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:document_chat/src/api_service.dart';
import 'package:document_chat/src/models/document.dart';
import 'package:document_chat/src/models/chat_message.dart';
import 'package:document_chat/src/models/search_result.dart';

// Provides the API service instance
final apiServiceProvider = Provider((ref) => ApiService());

// Manages the list of documents for the admin screen
final documentsProvider = FutureProvider<List<Document>>((ref) async {
  return ref.watch(apiServiceProvider).listDocuments();
});

// Manages chat messages
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref.watch(apiServiceProvider));
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ApiService _apiService;

  ChatNotifier(this._apiService) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _apiService.getChatHistory();

      final messages = <ChatMessage>[];
      for (final item in history) {
        final sender = item['sender'] as String;
        final content = item['content'] as String;

        if (sender == 'user') {
          messages.add(ChatMessage(sender: Sender.user, text: content));
        } else if (sender == 'ai_result') {
          // Parse JSON and create SearchResult (same as live chat)
          try {
            final resultData = json.decode(content);
            final searchResult = SearchResult(
              documentName: resultData['document_name'],
              pageNumber: resultData['page_number'],
              contentSnippet: resultData['content_snippet'],
              documentId: resultData['document_id'],
              downloadUrl: resultData['download_url'],
            );
            messages.add(ChatMessage(sender: Sender.ai, searchResult: searchResult));
          } catch (e) {
            // Fallback to text if JSON parsing fails
            messages.add(ChatMessage(sender: Sender.ai, text: content));
          }
        } else if (sender == 'ai') {
          // Handle simple AI text messages (like "No relevant information found")
          messages.add(ChatMessage(sender: Sender.ai, text: content));
        }
      }

      state = messages;
    } catch (e) {
      debugPrint('Failed to load chat history: $e');
    }
  }

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

  Future<void> clearHistory() async {
    await _apiService.clearChatHistory();
    state = [];
  }
}
