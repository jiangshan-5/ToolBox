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
            
            final theme = Theme.of(context);
            final surfaceColor = theme.colorScheme.surface;
            final onSurfaceColor = theme.colorScheme.onSurface;
            final primaryColor = theme.colorScheme.primary;

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
                    color: surfaceColor.withOpacity(0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(color: onSurfaceColor.withOpacity(0.08)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: onSurfaceColor.withOpacity(0.24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.border_color_rounded, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '本章划线与笔记管理',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurfaceColor),
                          ),
                          const Spacer(),
                          Text(
                            '共 ${paragraphs.length} 段',
                            style: TextStyle(fontSize: 12, color: onSurfaceColor.withOpacity(0.38)),
                          ),
                        ],
                      ),
                      Divider(height: 24, color: onSurfaceColor.withOpacity(0.1)),
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
                                color: isHigh ? onSurfaceColor.withOpacity(0.06) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isHigh ? primaryColor.withOpacity(0.3) : onSurfaceColor.withOpacity(0.04),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 13),
                                  ),
                                  if (note.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.note_alt_rounded, size: 12, color: primaryColor),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              note,
                                              style: TextStyle(color: onSurfaceColor.withOpacity(0.7), fontSize: 11, fontStyle: FontStyle.italic),
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
                                          color: isHigh ? Colors.amber : onSurfaceColor.withOpacity(0.54),
                                        ),
                                        label: Text(
                                          isHigh ? '取消划线' : '添加划线',
                                          style: TextStyle(color: isHigh ? Colors.amber : onSurfaceColor.withOpacity(0.54), fontSize: 12),
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
                                        icon: Icon(Icons.note_alt_rounded, size: 14, color: primaryColor),
                                        label: Text(
                                          note.isNotEmpty ? '编辑想法' : '写想法',
                                          style: TextStyle(color: primaryColor, fontSize: 12),
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
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('写下您的阅读想法', style: TextStyle(color: onSurfaceColor, fontSize: 16)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(color: onSurfaceColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: '这一刻的想法...',
              hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.3)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: onSurfaceColor.withOpacity(0.24)),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消', style: TextStyle(color: onSurfaceColor.withOpacity(0.38))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
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
              child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
