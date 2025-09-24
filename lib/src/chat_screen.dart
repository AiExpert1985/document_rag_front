// lib/src/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:document_chat/src/providers.dart';
import 'package:document_chat/src/models/chat_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatProvider, (_, __) {
      _scrollToBottom();
    });

    final messages = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => ref.read(chatProvider.notifier).clearHistory(),
          ),
          TextButton(
            onPressed: () => context.go('/admin'),
            child: const Text('Go to Admin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessage(message);
                  },
                ),
              ),
              _buildChatInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.sender == Sender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue[100]
              : (message.error != null ? Colors.red[100] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: _buildMessageContent(message),
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    if (message.sender == Sender.user) {
      final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(message.text ?? "");
      return Text(
        message.text ?? "",
        textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
      );
    }

    if (message.error != null) {
      return Text(message.error!, style: const TextStyle(color: Colors.black87));
    }

    // Handle SearchResult (both live and history messages use this now)
    if (message.searchResult != null) {
      final result = message.searchResult!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            const TextSpan(text: 'Source: ', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: '${result.documentName} (Page ${result.pageNumber})'),
          ])),
          const SizedBox(height: 8),
          Text(
            result.contentSnippet,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.download_for_offline, size: 18),
              label: const Text('View Source'),
              onPressed: () => _launchURL(Uri.parse(result.downloadUrl)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      );
    }

    // Handle simple AI text messages (fallback for any text-only messages)
    if (message.text != null) {
      final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(message.text!);
      return Text(
        message.text!,
        textDirection: hasArabic ? TextDirection.rtl : TextDirection.ltr,
        style: const TextStyle(color: Colors.black87),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Ask a question...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(_controller.text.trim());
      _controller.clear();
    }
  }
}
