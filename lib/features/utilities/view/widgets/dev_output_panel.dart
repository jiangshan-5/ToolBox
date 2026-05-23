import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class DevOutputPanel extends StatelessWidget {
  final TextEditingController outputController;
  final int outputLen;
  final int outputBytes;
  final Color activeOpColor;
  final bool isWide;

  const DevOutputPanel({
    super.key,
    required this.outputController,
    required this.outputLen,
    required this.outputBytes,
    required this.activeOpColor,
    required this.isWide,
  });

  void _shareResult() {
    final text = outputController.text.trim();
    if (text.isEmpty) return;
    Share.share(text, subject: '开发者编码转换结果');
  }

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
          '📤 变换输出结果',
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
                controller: outputController,
                maxLines: isWide ? 12 : 8,
                readOnly: true,
                style: TextStyle(
                  color: activeOpColor,
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText: '格式化或编码后的结果将在这里自动展示...',
                  hintStyle: TextStyle(color: Colors.white12, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          color: activeOpColor,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: '复制结果',
                        onPressed: outputLen == 0
                            ? null
                            : () {
                                Clipboard.setData(
                                  ClipboardData(text: outputController.text),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('转换结果已成功复制'),
                                    backgroundColor: activeOpColor.withOpacity(
                                      0.2,
                                    ),
                                  ),
                                );
                              },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          Icons.share_rounded,
                          color: activeOpColor,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: '分享结果',
                        onPressed: outputLen == 0 ? null : _shareResult,
                      ),
                    ],
                  ),
                  Text(
                    '共 $outputLen 字符 | $outputBytes 字节',
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
