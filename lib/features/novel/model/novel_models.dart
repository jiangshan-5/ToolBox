import 'package:flutter/foundation.dart';

class BookSourceRule {
  final String id;
  final String sourceName;
  final String sourceUrl;
  final String searchUrl;
  final String ruleJson;
  final bool isActive;
  final bool isValid;
  final bool isPrivate;
  final bool isAbyss;

  BookSourceRule({
    required this.id,
    required this.sourceName,
    required this.sourceUrl,
    required this.searchUrl,
    required this.ruleJson,
    required this.isActive,
    required this.isValid,
    required this.isPrivate,
    required this.isAbyss,
  });

  factory BookSourceRule.fromJson(Map<String, dynamic> json) {
    return BookSourceRule(
      id: json['id'] ?? '',
      sourceName: json['source_name'] ?? '',
      sourceUrl: json['source_url'] ?? '',
      searchUrl: json['search_url'] ?? '',
      ruleJson: json['rule_json'] ?? '',
      isActive: json['is_active'] ?? false,
      isValid: json['is_valid'] ?? false,
      isPrivate: json['is_private'] ?? false,
      isAbyss: json['is_abyss'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_name': sourceName,
      'source_url': sourceUrl,
      'search_url': searchUrl,
      'rule_json': ruleJson,
      'is_active': isActive,
      'is_valid': isValid,
      'is_private': isPrivate,
      'is_abyss': isAbyss,
    };
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final String summary;
  final String? currentSourceId;
  final bool isAbyss;
  
  // Custom helper field for search results
  final String? bookUrl;
  final String? sourceId;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.summary,
    this.currentSourceId,
    required this.isAbyss,
    this.bookUrl,
    this.sourceId,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      coverUrl: json['cover_url'] ?? '',
      summary: json['summary'] ?? '',
      currentSourceId: json['current_source_id'],
      isAbyss: json['is_abyss'] ?? false,
      bookUrl: json['book_url'],
      sourceId: json['source_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'summary': summary,
      'current_source_id': currentSourceId,
      'is_abyss': isAbyss,
      'book_url': bookUrl,
      'source_id': sourceId,
    };
  }
}

class BookChapter {
  final String id;
  final String bookId;
  final int chapterIndex;
  final String title;
  final String sourceChapterUrl;
  final String? content;

  BookChapter({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.title,
    required this.sourceChapterUrl,
    this.content,
  });

  factory BookChapter.fromJson(Map<String, dynamic> json) {
    return BookChapter(
      id: json['id'] ?? '',
      bookId: json['book_id'] ?? '',
      chapterIndex: json['chapter_index'] ?? 0,
      title: json['title'] ?? '',
      sourceChapterUrl: json['source_chapter_url'] ?? '',
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'chapter_index': chapterIndex,
      'title': title,
      'source_chapter_url': sourceChapterUrl,
      'content': content,
    };
  }
}

class ReadingProgress {
  final String id;
  final String userId;
  final String bookId;
  final int lastReadChapterIndex;
  final int lastReadCharOffset;
  final String updatedAt;
  final Book? book;

  ReadingProgress({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.lastReadChapterIndex,
    required this.lastReadCharOffset,
    required this.updatedAt,
    this.book,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      bookId: json['book_id'] ?? '',
      lastReadChapterIndex: json['last_read_chapter_index'] ?? 0,
      lastReadCharOffset: json['last_read_char_offset'] ?? 0,
      updatedAt: json['updated_at'] ?? '',
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'last_read_chapter_index': lastReadChapterIndex,
      'last_read_char_offset': lastReadCharOffset,
      'updated_at': updatedAt,
      'book': book?.toJson(),
    };
  }

  ReadingProgress copyWith({
    int? lastReadChapterIndex,
    int? lastReadCharOffset,
    String? updatedAt,
    Book? book,
  }) {
    return ReadingProgress(
      id: id,
      userId: userId,
      bookId: bookId,
      lastReadChapterIndex: lastReadChapterIndex ?? this.lastReadChapterIndex,
      lastReadCharOffset: lastReadCharOffset ?? this.lastReadCharOffset,
      updatedAt: updatedAt ?? this.updatedAt,
      book: book ?? this.book,
    );
  }
}
