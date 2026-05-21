import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../features/dashboard/provider/tools_provider.dart';

class LedBannerScreen extends ConsumerStatefulWidget {
  const LedBannerScreen({super.key});

  @override
  ConsumerState<LedBannerScreen> createState() => _LedBannerScreenState();
}

class _LedBannerScreenState extends ConsumerState<LedBannerScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController(text: "CYBERPUNK NEON LED BANNER 🚀");
  
  double _fontSize = 64.0;
  double _scrollSpeed = 3.0; // 1 (Slow) to 10 (Fast)
  double _glowRadius = 15.0; // 0 to 30
  double _blinkFrequency = 0.0; // 0 (None) to 5 (Fast Hz)

  // Neon Gradient Presets
  int _selectedColorIndex = 0;
  final List<List<Color>> _neonGradients = [
    [const Color(0xFF00F2FE), const Color(0xFF4FACFE)], // Cyan Glow
    [const Color(0xFF00FF87), const Color(0xFF60EFFF)], // Lime Green
    [const Color(0xFFFF0844), const Color(0xFFFFB199)], // Hot Pink
    [const Color(0xFFFAD961), const Color(0xFFF76B1C)], // Amber Orange
    [const Color(0xFF7000FF), const Color(0xFFE200FF)], // Electric Purple/Pink
  ];

  final List<String> _colorNames = ["赛博青蓝", "荧光翠绿", "极光烈粉", "熔岩琥珀", "魔幻电紫"];

  // Background Theme Presets
  int _selectedBgIndex = 1; // Default Matrix Grid
  final List<String> _bgNames = ["极黑之夜", "矩阵微网", "深紫微光"];

  // Full Screen State
  bool _isFullscreen = false;
  
  // Blink state
  bool _blinkVisible = true;
  Timer? _blinkTimer;

  // Animation controller for dynamic preview marquee
  late AnimationController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _startBlinkTimer();

    // Telemetry: log tool launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logTelemetry();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _blinkTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _startBlinkTimer() {
    _blinkTimer?.cancel();
    if (_blinkFrequency <= 0.0) {
      setState(() {
        _blinkVisible = true;
      });
      return;
    }
    // Frequency in Hz: e.g. 1Hz = every 1000ms toggle. 5Hz = every 200ms toggle.
    final intervalMs = (1000 / (_blinkFrequency * 2)).round();
    _blinkTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (mounted) {
        setState(() {
          _blinkVisible = !_blinkVisible;
        });
      }
    });
  }

  void _logTelemetry() {
    try {
      ref.read(toolsAnalyticsProvider).logUsage(
        toolKey: 'led_banner',
        parameters: {
          'font_size': _fontSize.round(),
          'scroll_speed': _scrollSpeed,
          'glow_radius': _glowRadius.round(),
          'blink_frequency': _blinkFrequency,
          'color_theme': _colorNames[_selectedColorIndex],
          'bg_theme': _bgNames[_selectedBgIndex],
        },
        status: 'success',
        durationMs: 0,
      );
    } catch (_) {}
  }

  void _enterFullscreen() {
    setState(() {
      _isFullscreen = true;
    });
    // Configure system overlays and orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitFullscreen() {
    setState(() {
      _isFullscreen = false;
    });
    // Restore system overlays and orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _exitFullscreen();
          },
          child: GestureDetector(
            onTap: _exitFullscreen,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildBannerView(isFullscreen: true),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fullscreen_exit_rounded, color: Colors.white60, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "轻触屏幕退出全屏",
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'LED 手持弹幕',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded, color: Colors.cyanAccent, size: 28),
            tooltip: "进入全屏模式",
            onPressed: _enterFullscreen,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Cyberpunk Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF090714), Color(0xFF0F0B22), Color(0xFF040308)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. Live Preview Panel (Glassmorphic Outer, Black Inner Banner View)
                const Text(
                  '📺 实时效果预览',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: _neonGradients[_selectedColorIndex][0].withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: _buildBannerView(isFullscreen: false),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Control Form Options
                const Text(
                  '⚙️ 弹幕参数配置',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  borderColor: Colors.white.withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text Input fields
                        const Text(
                          "编辑弹幕内容",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: const InputDecoration(
                              hintText: '输入要滚动的文字...',
                              hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                              border: InputBorder.none,
                            ),
                            onChanged: (text) {
                              setState(() {}); // Trigger refresh of the layout
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Neon presets picker
                        const Text(
                          "发光霓虹色彩",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 42,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _neonGradients.length,
                            itemBuilder: (context, idx) {
                              final isSelected = idx == _selectedColorIndex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColorIndex = idx;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: _neonGradients[idx]),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: _neonGradients[idx][0].withOpacity(0.4),
                                          blurRadius: 10,
                                        ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _colorNames[idx],
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
                        const Text(
                          "背景画布特效",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(_bgNames.length, (idx) {
                            final isSelected = idx == _selectedBgIndex;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedBgIndex = idx;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(
                                    left: idx == 0 ? 0 : 6,
                                    right: idx == _bgNames.length - 1 ? 0 : 6,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.015),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.04),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _bgNames[idx],
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
                            const Text("文字大小", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text("${_fontSize.round()} PX", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _fontSize,
                          min: 32,
                          max: 120,
                          activeColor: Colors.cyanAccent,
                          inactiveColor: Colors.white10,
                          onChanged: (val) => setState(() => _fontSize = val),
                        ),

                        // Scroll Speed slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("滚动速度", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text("速度 ${_scrollSpeed.toStringAsFixed(1)}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _scrollSpeed,
                          min: 0.5,
                          max: 10.0,
                          activeColor: Colors.cyanAccent,
                          inactiveColor: Colors.white10,
                          onChanged: (val) => setState(() => _scrollSpeed = val),
                        ),

                        // Glow radius slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("霓虹辉光半径", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text("${_glowRadius.round()} Lm", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _glowRadius,
                          min: 0,
                          max: 30,
                          activeColor: Colors.cyanAccent,
                          inactiveColor: Colors.white10,
                          onChanged: (val) => setState(() => _glowRadius = val),
                        ),

                        // Blink rate slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("呼吸闪烁频率", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              _blinkFrequency <= 0.0 ? "常亮" : "${_blinkFrequency.toStringAsFixed(1)} Hz",
                              style: TextStyle(
                                color: _blinkFrequency <= 0 ? Colors.white30 : Colors.cyanAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _blinkFrequency,
                          min: 0.0,
                          max: 5.0,
                          activeColor: Colors.cyanAccent,
                          inactiveColor: Colors.white10,
                          onChanged: (val) {
                            setState(() {
                              _blinkFrequency = val;
                            });
                            _startBlinkTimer();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Fullscreen shortcut button
                GestureDetector(
                  onTap: _enterFullscreen,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fullscreen_rounded, color: Colors.black, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "💫 开启全屏沉浸播放 (横屏模式)",
                          style: TextStyle(color: Colors.black, fontSize: 13.5, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerView({required bool isFullscreen}) {
    return Stack(
      children: [
        // Background layer
        Positioned.fill(
          child: _buildBgDecoration(),
        ),
        // Marquee Text layer
        Positioned.fill(
          child: ClipRect(
            child: Opacity(
              opacity: _blinkVisible ? 1.0 : 0.0,
              child: LedMarqueeWidget(
                text: _textController.text.isEmpty ? "输入一些内容" : _textController.text,
                fontSize: isFullscreen ? _fontSize * 1.5 : _fontSize * 0.7,
                speedMultiplier: _scrollSpeed,
                glowColor: _neonGradients[_selectedColorIndex][0],
                neonGradient: _neonGradients[_selectedColorIndex],
                glowRadius: _glowRadius,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBgDecoration() {
    if (_selectedBgIndex == 0) {
      // Pure Black
      return Container(color: Colors.black);
    } else if (_selectedBgIndex == 1) {
      // Subtle dot matrix grid
      return CustomPaint(
        painter: GridMatrixPainter(dotColor: Colors.white.withOpacity(0.03)),
      );
    } else {
      // Deep Purple Glow background
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF160A2A), Color(0xFF000000)],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
      );
    }
  }
}

// Sub-widget for rendering continuous marquee scrolling smoothly
class LedMarqueeWidget extends StatefulWidget {
  final String text;
  final double fontSize;
  final double speedMultiplier;
  final Color glowColor;
  final List<Color> neonGradient;
  final double glowRadius;

  const LedMarqueeWidget({
    super.key,
    required this.text,
    required this.fontSize,
    required this.speedMultiplier,
    required this.glowColor,
    required this.neonGradient,
    required this.glowRadius,
  });

  @override
  State<LedMarqueeWidget> createState() => _LedMarqueeWidgetState();
}

class _LedMarqueeWidgetState extends State<LedMarqueeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _containerWidth = 0;
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    // Use an animation controller that iterates continuously
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Will be scaled dynamically
    );
    _controller.addListener(() {
      setState(() {});
    });
    _updateSpeedAndDuration();
  }

  @override
  void didUpdateWidget(covariant LedMarqueeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateTextWidth();
    _updateSpeedAndDuration();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculateTextWidth() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace', // keeps sizing stable
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    setState(() {
      _textWidth = textPainter.width;
    });
  }

  void _updateSpeedAndDuration() {
    if (_textWidth <= 0 || _containerWidth <= 0) return;

    // Total distance = container width + text width (to scroll completely off screen)
    final distance = _containerWidth + _textWidth;
    
    // Calculate seconds needed: distance divided by speed coefficient
    // speedMultiplier range: 0.5 (Slow) to 10 (Fast)
    // base speed is e.g. 100 pixels per second for multiplier=1
    final pixelsPerSecond = widget.speedMultiplier * 70.0;
    final seconds = distance / pixelsPerSecond;

    _controller.duration = Duration(milliseconds: (seconds * 1000).round());
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_containerWidth != constraints.maxWidth) {
          _containerWidth = constraints.maxWidth;
          // recalculate on next frame to ensure safe layout pass
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _calculateTextWidth();
              _updateSpeedAndDuration();
            }
          });
        }

        // Compute horizontal offset
        // 0.0 value: text starts at offscreen right (_containerWidth)
        // 1.0 value: text reaches offscreen left (-_textWidth)
        final xOffset = _containerWidth - (_containerWidth + _textWidth) * _controller.value;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Transform.translate(
              offset: Offset(xOffset, 0),
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: widget.neonGradient,
                  ).createShader(Offset.zero & bounds.size);
                },
                child: Text(
                  widget.text,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.white, // fall back color before shader mask
                    shadows: widget.glowRadius > 0
                        ? [
                            Shadow(
                              color: widget.glowColor.withOpacity(0.8),
                              blurRadius: widget.glowRadius,
                            ),
                            Shadow(
                              color: widget.glowColor.withOpacity(0.5),
                              blurRadius: widget.glowRadius * 1.5,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Subtle grid painter for custom tech background
class GridMatrixPainter extends CustomPainter {
  final Color dotColor;
  final double gridSpacing;
  final double dotRadius;

  GridMatrixPainter({
    required this.dotColor,
    this.gridSpacing = 16.0,
    this.dotRadius = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += gridSpacing) {
      for (double y = 0; y < size.height; y += gridSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridMatrixPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor ||
      oldDelegate.gridSpacing != gridSpacing ||
      oldDelegate.dotRadius != dotRadius;
}
