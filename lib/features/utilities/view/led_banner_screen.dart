import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/dashboard/provider/tools_provider.dart';
import '../../../core/widgets/pipeline_wrapper.dart';
import 'widgets/led_marquee_widget.dart';
import 'widgets/led_grid_painter.dart';
import 'widgets/led_control_panel.dart';

class LedBannerScreen extends ConsumerStatefulWidget {
  final String? initialText;
  const LedBannerScreen({super.key, this.initialText});

  @override
  ConsumerState<LedBannerScreen> createState() => _LedBannerScreenState();
}

class _LedBannerScreenState extends ConsumerState<LedBannerScreen>
    with TickerProviderStateMixin {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;
  Color get borderDividerColor =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  late final TextEditingController _textController;

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

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.initialText ?? "CYBERPUNK NEON LED BANNER 🚀",
    );
    _startBlinkTimer();
    // Telemetry: log tool launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logTelemetry();
    });
  }

  @override
  void dispose() {
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
      ref
          .read(toolsAnalyticsProvider)
          .logUsage(
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
                Positioned.fill(child: _buildBannerView(isFullscreen: true)),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fullscreen_exit_rounded,
                          color: subTextColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "轻触屏幕退出全屏",
                          style: TextStyle(color: subTextColor, fontSize: 11),
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'LED 手持弹幕',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.fullscreen_rounded,
              color: Colors.cyanAccent,
              size: 28,
            ),
            tooltip: "进入全屏模式",
            onPressed: _enterFullscreen,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PipelineWrapper(
        toolKey: 'led_banner',
        controller: _textController,
        child: Stack(
          children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF090714),
                  Color(0xFF0F0B22),
                  Color(0xFF040308),
                ],
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
                Text(
                  '📺 实时效果预览',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: borderDividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: _neonGradients[_selectedColorIndex][0]
                              .withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: _buildBannerView(isFullscreen: false),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '⚙️ 弹幕参数配置',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                LedControlPanel(
                  textController: _textController,
                  fontSize: _fontSize,
                  onFontSizeChanged: (val) => setState(() => _fontSize = val),
                  scrollSpeed: _scrollSpeed,
                  onScrollSpeedChanged: (val) =>
                      setState(() => _scrollSpeed = val),
                  glowRadius: _glowRadius,
                  onGlowRadiusChanged: (val) =>
                      setState(() => _glowRadius = val),
                  blinkFrequency: _blinkFrequency,
                  onBlinkFrequencyChanged: (val) =>
                      setState(() => _blinkFrequency = val),
                  selectedColorIndex: _selectedColorIndex,
                  onColorIndexChanged: (idx) =>
                      setState(() => _selectedColorIndex = idx),
                  selectedBgIndex: _selectedBgIndex,
                  onBgIndexChanged: (idx) =>
                      setState(() => _selectedBgIndex = idx),
                  neonGradients: _neonGradients,
                  colorNames: _colorNames,
                  bgNames: _bgNames,
                  onBlinkFrequencySliderFinished: _startBlinkTimer,
                ),
                const SizedBox(height: 20),
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
                        Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "💫 开启全屏沉浸播放 (横屏模式)",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
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
    ),
  );
}

  Widget _buildBannerView({required bool isFullscreen}) {
    return Stack(
      children: [
        Positioned.fill(child: _buildBgDecoration()),
        Positioned.fill(
          child: ClipRect(
            child: Opacity(
              opacity: _blinkVisible ? 1.0 : 0.0,
              child: LedMarqueeWidget(
                text: _textController.text.isEmpty
                    ? "输入一些内容"
                    : _textController.text,
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
      return Container(color: Colors.black);
    } else if (_selectedBgIndex == 1) {
      return CustomPaint(
        painter: GridMatrixPainter(
          dotColor: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.03),
        ),
      );
    } else {
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
