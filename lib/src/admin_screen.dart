// lib/src/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:document_chat/src/providers.dart';
import 'package:document_chat/src/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  Future<void> _launchURL(Uri url, BuildContext context) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // CHANGED: Add this 'mounted' check to fix the warning.
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Manage Documents'),
        actions: [
          TextButton(
            onPressed: () => context.go('/chat'),
            child: const Text('Go to Chat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload PDF'),
                  onPressed: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                    );

                    if (result == null) return;
                    if (!context.mounted) return;

                    final file = result.files.first;

                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Uploading...')));

                    try {
                      await ref.read(apiServiceProvider).uploadDocument(file);
                      if (!context.mounted) return;

                      ref.invalidate(documentsProvider);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Upload successful!')));
                    } on ApiException catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                    }
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: documentsAsync.when(
                  data: (docs) {
                    if (docs.isEmpty) {
                      return const Center(child: Text('No documents uploaded yet.'));
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(doc.filename),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download, color: Colors.blue),
                                tooltip: 'Download',
                                onPressed: () {
                                  _launchURL(Uri.parse(doc.downloadUrl), context);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () async {
                                  await ref.read(apiServiceProvider).deleteDocument(doc.id);
                                  ref.invalidate(documentsProvider);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error loading documents: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
