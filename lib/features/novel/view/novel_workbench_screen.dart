import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../provider/novel_provider.dart';
import 'widgets/novel_shelf_tab.dart';
import 'widgets/book_oasis_tab.dart';
import 'novel_search_screen.dart';
import 'abyss_chamber_screen.dart';
import '../../../../core/widgets/dynamic_background.dart';

class NovelWorkbenchScreen extends ConsumerStatefulWidget {
  const NovelWorkbenchScreen({super.key});

  @override
  ConsumerState<NovelWorkbenchScreen> createState() => _NovelWorkbenchScreenState();
}

class _NovelWorkbenchScreenState extends ConsumerState<NovelWorkbenchScreen> {
  int _activeTab = 0;
  
  // Timing parameters for the secret 5s gesture trigger
  Timer? _gestureTimer;
  int _longPressSeconds = 0;
  bool _isTriggeringAbyss = false;

  @override
  void initState() {
    super.initState();
    // Warm-start loading normal bookshelf
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(novelProvider.notifier).fetchBookshelf(false);
    });
  }

  @override
  void dispose() {
    _gestureTimer?.cancel();
    super.dispose();
  }

  void _onGestureStart() {
    _longPressSeconds = 0;
    _gestureTimer?.cancel();
    _gestureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _longPressSeconds++;
      if (_longPressSeconds >= 5) {
        timer.cancel();
        _triggerAbyssChamberAccess();
      } else {
        // Micro feedback sound or vibration tick
        HapticFeedback.lightImpact();
      }
    });
  }

  void _onGestureEnd() {
    _gestureTimer?.cancel();
  }

  void _triggerAbyssChamberAccess() async {
    setState(() {
      _isTriggeringAbyss = true;
    });
    
    // Intense physical vibration sequence
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();

    if (mounted) {
      setState(() {
        _isTriggeringAbyss = false;
      });
      // Redirect to Abyss Chamber Screen
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => const AbyssChamberScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
              child: ScaleTransition(
                scale: animation.drive(Tween<double>(begin: 0.9, end: 1.0)),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Force a dark theme for the entire novel workbench section to ensure high readability
    // of all text elements and create a gorgeous immersive reading environment
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.pinkAccent,
        brightness: Brightness.dark,
        surface: const Color(0xFF0F0C29), // deep midnight purple-blue space background
      ),
      useMaterial3: true,
    );

    return Theme(
      data: darkTheme,
      child: Builder(
        builder: (context) {
          final localTheme = Theme.of(context);
          final primaryColor = localTheme.colorScheme.primary;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              // Hidden 5s long-press gesture detector on the Title Logo area
              title: GestureDetector(
                onLongPressStart: (_) => _onGestureStart(),
                onLongPressEnd: (_) => _onGestureEnd(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '智能净化阅读器',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white70),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NovelSearchScreen(inAbyss: false),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                const DynamicBackground(child: SizedBox.expand()),
                
                SafeArea(
                  child: Column(
                    children: [
                      _buildTabBar(),
                      
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _activeTab == 0
                              ? NovelShelfTab(
                                  key: const ValueKey('ShelfTab'),
                                  inAbyss: false,
                                  onOpenSearch: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const NovelSearchScreen(inAbyss: false),
                                      ),
                                    );
                                  },
                                )
                              : BookOasisTab(
                                  key: const ValueKey('OasisTab'),
                                  inAbyss: false,
                                  onSearchTriggered: (query) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NovelSearchScreen(
                                          inAbyss: false,
                                          initialQuery: query,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Portal particle transition cover overlay
                if (_isTriggeringAbyss)
                  Positioned.fill(
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Colors.purple.withOpacity(0.3),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                '🌌 正在撕裂空间穿梭至深渊...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? Colors.pinkAccent.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '📚 我的书架',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? Colors.pinkAccent.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '🔮 发现绿洲',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
