import 'package:flutter/material.dart';
import 'dev_encoder_constants.dart';

class DevSelectorChips extends StatelessWidget {
  final String activeOperation;
  final ValueChanged<String> onOperationChanged;

  const DevSelectorChips({
    super.key,
    required this.activeOperation,
    required this.onOperationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🛠️ 选择编码或哈希函数',
          style: TextStyle(
            color: textColor,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: devOperations.length,
            itemBuilder: (context, idx) {
              final op = devOperations[idx];
              final isSelected = op.key == activeOperation;
              final opColor = op.color;

              return GestureDetector(
                onTap: () => onOperationChanged(op.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? opColor.withOpacity(0.12)
                        : (isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? opColor
                          : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                      width: 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: opColor.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        op.icon,
                        color: isSelected ? opColor : Colors.white60,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        op.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
