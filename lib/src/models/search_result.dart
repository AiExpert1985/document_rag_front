// src/models/search_result.dart
class SearchResult {
  final String documentName;
  final int pageNumber;
  final String contentSnippet;
  final String documentId;

  SearchResult({
    required this.documentName,
    required this.pageNumber,
    required this.contentSnippet,
    required this.documentId,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      documentName: json['document_name'] as String,
      pageNumber: json['page_number'] as int,
      contentSnippet: json['content_snippet'] as String,
      documentId: json['document_id'] as String,
    );
  }
}
