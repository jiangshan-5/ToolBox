import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class NovelReaderSkeleton extends StatefulWidget {
  final Color themeBg;
  final Color themeText;

  const NovelReaderSkeleton({
    super.key,
    required this.themeBg,
    required this.themeText,
  });

  @override
  State<NovelReaderSkeleton> createState() => _NovelReaderSkeletonState();
}

class _NovelReaderSkeletonState extends State<NovelReaderSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shimmerColor = widget.themeText.withOpacity(0.15);
    return Scaffold(
      backgroundColor: widget.themeBg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: 0.3 + (_controller.value * 0.5), // Pulses between 0.3 and 0.8
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top header line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(width: 80, height: 12, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                          Container(width: 40, height: 12, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // Title skeleton
                      Container(width: 160, height: 28, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6))),
                      const SizedBox(height: 36),
                      // Paragraph 1
                      _buildParagraph(shimmerColor, [0.95, 0.9, 0.92, 0.4]),
                      const SizedBox(height: 24),
                      // Paragraph 2
                      _buildParagraph(shimmerColor, [0.93, 0.95, 0.85, 0.35]),
                      const SizedBox(height: 24),
                      // Paragraph 3
                      _buildParagraph(shimmerColor, [0.9, 0.92, 0.94, 0.78, 0.45]),
                      const SizedBox(height: 24),
                      // Paragraph 4
                      _buildParagraph(shimmerColor, [0.95, 0.93, 0.3]),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildParagraph(Color color, List<double> widths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widths.map((w) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FractionallySizedBox(
            widthFactor: w,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
