import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/dynamic_effects.dart';

class DailyBoardQuoteStudio extends StatelessWidget {
  final bool isLoadingQuote;
  final String quoteText;
  final String quoteAuthor;
  final String quoteSource;
  final int selectedGradientIndex;
  final double cardOpacity;
  final double textSize;
  final TextAlign textAlign;
  final List<List<Color>> cardGradients;
  final List<String> gradientNames;
  final VoidCallback onFetchQuote;
  final VoidCallback onCopyQuote;
  final ValueChanged<int> onGradientChanged;
  final ValueChanged<double> onTextSizeChanged;
  final ValueChanged<double> onCardOpacityChanged;
  final ValueChanged<TextAlign> onTextAlignChanged;

  const DailyBoardQuoteStudio({
    super.key,
    required this.isLoadingQuote,
    required this.quoteText,
    required this.quoteAuthor,
    required this.quoteSource,
    required this.selectedGradientIndex,
    required this.cardOpacity,
    required this.textSize,
    required this.textAlign,
    required this.cardGradients,
    required this.gradientNames,
    required this.onFetchQuote,
    required this.onCopyQuote,
    required this.onGradientChanged,
    required this.onTextSizeChanged,
    required this.onCardOpacityChanged,
    required this.onTextAlignChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;

    return GlassCard(
      borderColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Card with custom properties
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 180),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: cardGradients[selectedGradientIndex],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cardGradients[selectedGradientIndex][0]
                          .withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        "一 言 • H I T O K O T O",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    isLoadingQuote
                        ? const Center(
                            child: SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                color: Colors.white70,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Text(
                            "“$quoteText”",
                            textAlign: textAlign,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: cardOpacity,
                              ),
                              fontSize: textSize,
                              fontWeight: FontWeight.bold,
                              height: 1.6,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 20),
                    if (!isLoadingQuote)
                      Text(
                        "—— $quoteAuthor 《$quoteSource》",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Background Selection Slider
            Text(
              "选择背景渐变：",
              style: TextStyle(color: subTextColor, fontSize: 11),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cardGradients.length,
                itemBuilder: (context, index) {
                  final isSelected = index == selectedGradientIndex;
                  return GestureDetector(
                    onTap: () => onGradientChanged(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? Colors.cyanAccent : Colors.cyan.shade600)
                              : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                        gradient: LinearGradient(
                          colors: cardGradients[index],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        gradientNames[index],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "卡片字体大小：",
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                      Slider(
                        value: textSize,
                        min: 12.0,
                        max: 20.0,
                        activeColor: isDark ? Colors.cyanAccent : Colors.cyan.shade600,
                        inactiveColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        onChanged: onTextSizeChanged,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "卡片透明度：",
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                      Slider(
                        value: cardOpacity,
                        min: 0.5,
                        max: 1.0,
                        activeColor: isDark ? Colors.cyanAccent : Colors.cyan.shade600,
                        inactiveColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                        onChanged: onCardOpacityChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Alignment selector
                Row(
                  children: [
                    Text(
                      "对齐方式：",
                      style: TextStyle(color: subTextColor, fontSize: 11),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.align_horizontal_left_rounded,
                        color: textAlign == TextAlign.left
                            ? (isDark ? Colors.cyanAccent : Colors.cyan.shade700)
                            : faintTextColor,
                        size: 18,
                      ),
                      onPressed: () => onTextAlignChanged(TextAlign.left),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.align_horizontal_center_rounded,
                        color: textAlign == TextAlign.center
                            ? (isDark ? Colors.cyanAccent : Colors.cyan.shade700)
                            : faintTextColor,
                        size: 18,
                      ),
                      onPressed: () => onTextAlignChanged(TextAlign.center),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.align_horizontal_right_rounded,
                        color: textAlign == TextAlign.right
                            ? (isDark ? Colors.cyanAccent : Colors.cyan.shade700)
                            : faintTextColor,
                        size: 18,
                      ),
                      onPressed: () => onTextAlignChanged(TextAlign.right),
                    ),
                  ],
                ),

                // Studio actions
                Row(
                  children: [
                    ScaleOnTap(
                      onTap: onFetchQuote,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cached_rounded,
                              color: isDark ? Colors.cyanAccent.shade100 : Colors.cyan.shade800,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "随机换一句",
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ScaleOnTap(
                      onTap: onCopyQuote,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [Colors.cyanAccent, const Color(0xFF00E5FF)]
                                : [Colors.cyan.shade400, Colors.cyan.shade600],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.cyanAccent : Colors.cyan).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              color: isDark ? Colors.black87 : Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "复制卡片",
                              style: TextStyle(
                                color: isDark ? Colors.black87 : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
