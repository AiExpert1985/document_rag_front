// src/models/chat_message.dart
import 'package:document_chat/src/models/search_result.dart';

enum Sender { user, ai }

class ChatMessage {
  final Sender sender;
  final String? text; // For user messages
  final SearchResult? searchResult; // For AI search results
  final String? error; // For error messages from the AI

  ChatMessage({
    required this.sender,
    this.text,
    this.searchResult,
    this.error,
  });
}
