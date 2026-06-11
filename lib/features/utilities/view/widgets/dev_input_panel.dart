import 'package:flutter/material.dart';

class DevInputPanel extends StatelessWidget {
  final TextEditingController inputController;
  final int inputLen;
  final int inputBytes;
  final bool isWide;
  final VoidCallback onClear;

  const DevInputPanel({
    super.key,
    required this.inputController,
    required this.inputLen,
    required this.inputBytes,
    required this.isWide,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black38;
    final Color borderDividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📥 贴入原始文本',
          style: TextStyle(
            color: textColor,
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.02)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderDividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: inputController,
                maxLines: isWide ? 12 : 5,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: '请贴入待处理的字符串或JSON数据...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black38,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: onClear,
                    child: const Text(
                      '清空输入',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '共 $inputLen 字符 | $inputBytes 字节',
                    style: TextStyle(color: faintTextColor, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
