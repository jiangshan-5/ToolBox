import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';

class LedControlPanel extends StatelessWidget {
  final TextEditingController textController;
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final double scrollSpeed;
  final ValueChanged<double> onScrollSpeedChanged;
  final double glowRadius;
  final ValueChanged<double> onGlowRadiusChanged;
  final double blinkFrequency;
  final ValueChanged<double> onBlinkFrequencyChanged;
  final int selectedColorIndex;
  final ValueChanged<int> onColorIndexChanged;
  final int selectedBgIndex;
  final ValueChanged<int> onBgIndexChanged;
  final List<List<Color>> neonGradients;
  final List<String> colorNames;
  final List<String> bgNames;
  final VoidCallback onBlinkFrequencySliderFinished;

  const LedControlPanel({
    super.key,
    required this.textController,
    required this.fontSize,
    required this.onFontSizeChanged,
    required this.scrollSpeed,
    required this.onScrollSpeedChanged,
    required this.glowRadius,
    required this.onGlowRadiusChanged,
    required this.blinkFrequency,
    required this.onBlinkFrequencyChanged,
    required this.selectedColorIndex,
    required this.onColorIndexChanged,
    required this.selectedBgIndex,
    required this.onBgIndexChanged,
    required this.neonGradients,
    required this.colorNames,
    required this.bgNames,
    required this.onBlinkFrequencySliderFinished,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;
    final Color borderDividerColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    return GlassCard(
      borderColor: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Input fields
            Text(
              "编辑弹幕内容",
              style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                ),
              ),
              child: TextField(
                controller: textController,
                style: TextStyle(color: textColor, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: '输入要滚动的文字...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Neon presets picker
            Text(
              "发光霓虹色彩",
              style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: neonGradients.length,
                itemBuilder: (context, idx) {
                  final isSelected = idx == selectedColorIndex;
                  return GestureDetector(
                    onTap: () => onColorIndexChanged(idx),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: neonGradients[idx]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.0,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: neonGradients[idx][0].withOpacity(0.4),
                              blurRadius: 10,
                            ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        colorNames[idx],
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Background styles picker
            Text(
              "背景画布特效",
              style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(bgNames.length, (idx) {
                final isSelected = idx == selectedBgIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onBgIndexChanged(idx),
                    child: Container(
                      margin: EdgeInsets.only(
                        left: idx == 0 ? 0 : 6,
                        right: idx == bgNames.length - 1 ? 0 : 6,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? borderDividerColor : (isDark ? Colors.white.withOpacity(0.015) : Colors.black.withOpacity(0.02)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.cyanAccent.withOpacity(0.5) : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        bgNames[idx],
                        style: TextStyle(
                          color: isSelected ? Colors.cyanAccent : Colors.white60,
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),

            // Font size control slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("文字大小", style: TextStyle(color: subTextColor, fontSize: 12)),
                Text("${fontSize.round()} PX", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: fontSize,
              min: 32,
              max: 120,
              activeColor: Colors.cyanAccent,
              inactiveColor: Colors.white10,
              onChanged: onFontSizeChanged,
            ),

            // Scroll Speed slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("滚动速度", style: TextStyle(color: subTextColor, fontSize: 12)),
                Text("速度 ${scrollSpeed.toStringAsFixed(1)}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: scrollSpeed,
              min: 0.5,
              max: 10.0,
              activeColor: Colors.cyanAccent,
              inactiveColor: Colors.white10,
              onChanged: onScrollSpeedChanged,
            ),

            // Glow radius slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("霓虹辉光半径", style: TextStyle(color: subTextColor, fontSize: 12)),
                Text("${glowRadius.round()} Lm", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: glowRadius,
              min: 0,
              max: 30,
              activeColor: Colors.cyanAccent,
              inactiveColor: Colors.white10,
              onChanged: onGlowRadiusChanged,
            ),

            // Blink rate slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("呼吸闪烁频率", style: TextStyle(color: subTextColor, fontSize: 12)),
                Text(
                  blinkFrequency <= 0.0 ? "常亮" : "${blinkFrequency.toStringAsFixed(1)} Hz",
                  style: TextStyle(
                    color: blinkFrequency <= 0 ? Colors.white30 : Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: blinkFrequency,
              min: 0.0,
              max: 5.0,
              activeColor: Colors.cyanAccent,
              inactiveColor: Colors.white10,
              onChanged: (val) {
                onBlinkFrequencyChanged(val);
                onBlinkFrequencySliderFinished();
              },
            ),
          ],
        ),
      ),
    );
  }
}
