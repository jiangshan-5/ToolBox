import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:convert';
import '../../../../core/storage/local_storage.dart';

class ReaderAnnotationsSheet {
  static Map<String, Map<String, dynamic>> loadHighlights(WidgetRef ref, String bookId) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final jsonStr = prefs.getString('novel_highlights_$bookId');
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          return decoded.map((key, val) => MapEntry(key as String, Map<String, dynamic>.from(val as Map)));
        }
      }
    } catch (_) {}
    return {};
  }

  static void saveHighlights(WidgetRef ref, String bookId, Map<String, Map<String, dynamic>> highlights) {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString('novel_highlights_$bookId', jsonEncode(highlights));
    } catch (_) {}
  }

  static void show({
    required BuildContext context,
    required WidgetRef ref,
    required String bookId,
    required int chapterIndex,
    required String content,
    required VoidCallback onUpdate,
  }) {
    final paragraphs = content.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final highlights = loadHighlights(ref, bookId);
            final chapterHighlights = highlights[chapterIndex.toString()] ?? {};

            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0C29).withOpacity(0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.border_color_rounded, color: Colors.pinkAccent),
                          const SizedBox(width: 8),
                          const Text(
                            '本章划线与笔记管理',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            '共 ${paragraphs.length} 段',
                            style: const TextStyle(fontSize: 12, color: Colors.white38),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.white10),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: paragraphs.length,
                          itemBuilder: (context, idx) {
                            final pText = paragraphs[idx];
                            final key = pText.trim();
                            final data = chapterHighlights[key] ?? {};
                            final bool isHigh = data['isHighlighted'] ?? false;
                            final String note = data['note'] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isHigh ? Colors.white.withOpacity(0.06) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isHigh ? Colors.pinkAccent.withOpacity(0.3) : Colors.white.withOpacity(0.04),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  if (note.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.pinkAccent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.note_alt_rounded, size: 12, color: Colors.pinkAccent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              note,
                                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          final newHighlights = Map<String, Map<String, dynamic>>.from(highlights);
                                          final chKey = chapterIndex.toString();
                                          final newChapterHighlights = Map<String, dynamic>.from(newHighlights[chKey] ?? {});
                                          
                                          final bool nextHigh = !isHigh;
                                          newChapterHighlights[key] = {
                                            'isHighlighted': nextHigh,
                                            'note': note,
                                            'paragraphText': key,
                                          };
                                          newHighlights[chKey] = newChapterHighlights;
                                          saveHighlights(ref, bookId, newHighlights);
                                          setModalState(() {});
                                          onUpdate();
                                        },
                                        icon: Icon(
                                          isHigh ? Icons.edit_off_rounded : Icons.border_color_rounded,
                                          size: 14,
                                          color: isHigh ? Colors.amber : Colors.white54,
                                        ),
                                        label: Text(
                                          isHigh ? '取消划线' : '添加划线',
                                          style: TextStyle(color: isHigh ? Colors.amber : Colors.white54, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () {
                                          _showEditNoteDialog(
                                            context: context,
                                            ref: ref,
                                            bookId: bookId,
                                            chapterIndex: chapterIndex,
                                            pKey: key,
                                            currentNote: note,
                                            onSaveComplete: () {
                                              setModalState(() {});
                                              onUpdate();
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.note_alt_rounded, size: 14, color: Colors.pinkAccent),
                                        label: Text(
                                          note.isNotEmpty ? '编辑想法' : '写想法',
                                          style: const TextStyle(color: Colors.pinkAccent, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _showEditNoteDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String bookId,
    required int chapterIndex,
    required String pKey,
    required String currentNote,
    required VoidCallback onSaveComplete,
  }) {
    final controller = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF140D33),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('写下您的阅读想法', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '这一刻的想法...',
              hintStyle: const TextStyle(color: Colors.white30),
              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.pinkAccent), borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              onPressed: () {
                final highlights = loadHighlights(ref, bookId);
                final chKey = chapterIndex.toString();
                final chapterHighlights = Map<String, dynamic>.from(highlights[chKey] ?? {});
                
                final existing = chapterHighlights[pKey] ?? {};
                chapterHighlights[pKey] = {
                  'isHighlighted': existing['isHighlighted'] ?? false,
                  'note': controller.text.trim(),
                  'paragraphText': pKey,
                };
                
                highlights[chKey] = chapterHighlights;
                saveHighlights(ref, bookId, highlights);
                Navigator.pop(context);
                onSaveComplete();
              },
              child: const Text('保存', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
