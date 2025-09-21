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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All Data?'),
          content: const Text(
              'This will permanently delete all uploaded documents and their data. This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close the dialog
                try {
                  await ref.read(apiServiceProvider).clearAllDocuments();
                  ref.invalidate(documentsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All documents cleared successfully!')),
                    );
                  }
                } on ApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to clear documents: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
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
              // --- FIX IS HERE: The "Clear All" button is now at the top ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Document'), // Changed from 'Upload PDF'
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'pdf',
                            'jpg',
                            'jpeg',
                            'png',
                            'docx',
                            'doc'
                          ], // Expanded list
                        );

                        if (result == null || !context.mounted) return;

                        final file = result.files.first;

                        // Client-side validation
                        final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'docx', 'doc'];
                        final fileExtension = file.extension?.toLowerCase() ?? '';

                        if (!allowedExtensions.contains(fileExtension)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Unsupported file type: $fileExtension. Allowed: ${allowedExtensions.join(", ")}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Size validation (50MB limit)
                        const maxSizeBytes = 50 * 1024 * 1024;
                        if (file.size > maxSizeBytes) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File too large. Maximum size is 50MB.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Uploading...')));

                        try {
                          await ref.read(apiServiceProvider).uploadDocument(file);
                          ref.invalidate(documentsProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Upload successful!')));
                          }
                        } on ApiException catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                          }
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clear All Data'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                      onPressed: () => _showClearAllDialog(context, ref),
                    ),
                  ],
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
                          // --- FIX IS HERE: Removed the extra button from the list item ---
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
