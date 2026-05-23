import 'package:flutter/material.dart';
import '../../../../core/widgets/dynamic_effects.dart';
import '../../provider/randomizer_provider.dart';

class RandomOptionRow extends StatefulWidget {
  final String id;
  final String text;
  final double weight;
  final double probability;
  final RandomizerNotifier notifier;

  const RandomOptionRow({
    super.key,
    required this.id,
    required this.text,
    required this.weight,
    required this.probability,
    required this.notifier,
  });

  @override
  State<RandomOptionRow> createState() => _RandomOptionRowState();
}

class _RandomOptionRowState extends State<RandomOptionRow> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get faintTextColor => isDark ? Colors.white38 : Colors.black38;

  late final TextEditingController _textController;
  late final FocusNode _textFocus;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.text);
    _textFocus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant RandomOptionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !_textFocus.hasFocus) {
      _textController.text = widget.text;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final probPercent = widget.probability / 100.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _textController,
                  focusNode: _textFocus,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  onChanged: (v) => widget.notifier.updateOptionText(widget.id, v),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
                ),
                child: Text(
                  '中签率 🎯 ${widget.probability.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              ScaleOnTap(
                onTap: () => widget.notifier.removeWeightedOption(widget.id),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.delete_outline_rounded, color: faintTextColor, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
            ),
            clipBehavior: Clip.antiAlias,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: probPercent.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.pinkAccent, Color(0xFFFF4081)]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.pinkAccent,
              inactiveTrackColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
              thumbColor: Colors.pinkAccent,
              overlayColor: Colors.pinkAccent.withOpacity(0.15),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: widget.weight,
              min: 0.1,
              max: 10.0,
              divisions: 99,
              onChanged: (v) => widget.notifier.updateOptionWeight(widget.id, v),
            ),
          ),
        ],
      ),
    );
  }
}
