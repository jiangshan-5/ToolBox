import 'package:flutter/material.dart';
import '../../../../core/widgets/dynamic_effects.dart';
import '../../provider/randomizer_provider.dart';

class RandomRangeRow extends StatefulWidget {
  final int index;
  final int min;
  final int max;
  final bool active;
  final RandomizerNotifier notifier;

  const RandomRangeRow({
    super.key,
    required this.index,
    required this.min,
    required this.max,
    required this.active,
    required this.notifier,
  });

  @override
  State<RandomRangeRow> createState() => _RandomRangeRowState();
}

class _RandomRangeRowState extends State<RandomRangeRow> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;

  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late final FocusNode _minFocus;
  late final FocusNode _maxFocus;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.min.toString());
    _maxController = TextEditingController(text: widget.max.toString());
    _minFocus = FocusNode();
    _maxFocus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant RandomRangeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.min != widget.min && !_minFocus.hasFocus) {
      _minController.text = widget.min.toString();
    }
    if (oldWidget.max != widget.max && !_maxFocus.hasFocus) {
      _maxController.text = widget.max.toString();
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _minFocus.dispose();
    _maxFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleOnTap(
          onTap: () =>
              widget.notifier.toggleRangeActive(widget.index, !widget.active),
          child: Checkbox(
            value: widget.active,
            activeColor: isDark ? Colors.cyanAccent : Colors.cyan.shade700,
            checkColor: isDark ? Colors.black87 : Colors.white,
            onChanged: (v) =>
                widget.notifier.toggleRangeActive(widget.index, v!),
          ),
        ),
        Text(
          '区间 ${widget.index + 1}: ',
          style: TextStyle(color: subTextColor, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextFormField(
              controller: _minController,
              focusNode: _minFocus,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Min',
                hintStyle: TextStyle(color: isDark ? Colors.white12 : Colors.black26),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.015)
                    : Colors.black.withOpacity(0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => widget.notifier.updateRangeMin(
                widget.index,
                int.tryParse(v) ?? 0,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('~', style: TextStyle(color: isDark ? Colors.white24 : Colors.black38)),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextFormField(
              controller: _maxController,
              focusNode: _maxFocus,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Max',
                hintStyle: TextStyle(color: isDark ? Colors.white12 : Colors.black26),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.015)
                    : Colors.black.withOpacity(0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => widget.notifier.updateRangeMax(
                widget.index,
                int.tryParse(v) ?? 100,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
