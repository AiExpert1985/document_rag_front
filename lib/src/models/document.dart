// src/models/document.dart
class Document {
  final String id;
  final String filename;

  Document({
    required this.id,
    required this.filename,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      filename: json['filename'] as String,
    );
  }
}
