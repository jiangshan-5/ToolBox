import 'package:flutter/material.dart';
import 'dart:math';

class NovelTextPaginator {
  static List<int> paginate(
    String text,
    TextStyle style,
    double maxWidth,
    double maxHeight,
  ) {
    final List<int> pages = [0];
    if (text.isEmpty) return pages;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final double fontSize = style.fontSize ?? 18.0;
    final double lineHeight = style.height ?? 1.6;
    final double charArea = fontSize * fontSize * lineHeight;
    final int estimatedChars = max(100, (maxWidth * maxHeight / charArea).round());

    int start = 0;
    while (start < text.length) {
      int end = text.length;

      // Estimate the character range for this page
      int est = start + estimatedChars;
      if (est > text.length) est = text.length;

      textPainter.text = TextSpan(text: text.substring(start, est), style: style);
      textPainter.layout(maxWidth: maxWidth);

      int low, high;
      if (textPainter.height <= maxHeight) {
        // Fits! The end is >= est.
        if (est == text.length) {
          pages.add(est);
          start = est;
          continue;
        }
        low = est;
        high = start + (estimatedChars * 1.5).round();
        if (high > text.length) high = text.length;
        if (high < low) high = low;

        // Check if high fits
        textPainter.text = TextSpan(text: text.substring(start, high), style: style);
        textPainter.layout(maxWidth: maxWidth);
        if (textPainter.height <= maxHeight) {
          // Even high fits! Search between high and text.length
          if (high == text.length) {
            pages.add(high);
            start = high;
            continue;
          }
          low = high;
          high = text.length;
        } else {
          // low fits, high overflows. The end is in [low, high - 1]
          high = high - 1;
        }
      } else {
        // Overflows! The end is < est.
        high = est - 1;
        low = start + (estimatedChars * 0.5).round();
        if (low <= start) low = start + 1;
        if (low > high) low = high;

        // Check if low fits
        textPainter.text = TextSpan(text: text.substring(start, low), style: style);
        textPainter.layout(maxWidth: maxWidth);
        if (textPainter.height > maxHeight) {
          // Even low overflows! Search between start + 1 and low - 1
          high = low - 1;
          low = start + 1;
        }
      }

      // Narrowed binary search
      while (low <= high) {
        int mid = (low + high) ~/ 2;
        final sub = text.substring(start, mid);
        textPainter.text = TextSpan(text: sub, style: style);
        textPainter.layout(maxWidth: maxWidth);

        if (textPainter.height <= maxHeight) {
          end = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      }

      if (end <= start) {
        end = start + 1;
      }

      pages.add(end);
      start = end;
    }

    return pages;
  }
}
