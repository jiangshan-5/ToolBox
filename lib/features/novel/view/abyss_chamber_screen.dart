import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:sensors_plus/sensors_plus.dart';
import '../provider/novel_provider.dart';
import 'widgets/novel_shelf_tab.dart';
import 'widgets/book_oasis_tab.dart';
import 'novel_search_screen.dart';

class AbyssChamberScreen extends ConsumerStatefulWidget {
  const AbyssChamberScreen({super.key});

  @override
  ConsumerState<AbyssChamberScreen> createState() => _AbyssChamberScreenState();
}

class _AbyssChamberScreenState extends ConsumerState<AbyssChamberScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  bool _isUnlocked = false;
  String _pin = '';
  final String _correctPin = '9999'; // Secure midnight bypass PIN code
  String _unlockError = '';

  // Shake detector subscription
  StreamSubscription? _accelerometerSub;
  
  // Particle explosion controllers
  late AnimationController _explosionController;
  final List<ExplosionParticle> _particles = [];
  final Random _random = Random();

  // Navigation tab index inside Abyss Chamber
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Initialize accelerometer shaking detection
    _startShakeDetection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelerometerSub?.cancel();
    _explosionController.dispose();
    super.dispose();
  }

  /// App Lifecycle state monitoring (auto-lock when backgrounded)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Wreck-safety: instantly destroy sandbox state and self-lock
      _selfLockAndExit();
    }
  }

  /// Shake detection using sensors_plus
  void _startShakeDetection() {
    try {
      _accelerometerSub = userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          // Calculate force vector
          final double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          if (acceleration > 15.0) {
            // Physical shake detected! Revert immediately to protect privacy
            _selfLockAndExit();
          }
        },
        onError: (error) {
          // Silent ignore: sensor not supported on emulators or desktop PCs
        },
        cancelOnError: false,
      );
    } catch (_) {
      // Catch platform-level start errors on desktop
    }
  }

  void _selfLockAndExit() {
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 安全自锁机制已生效，深渊密室已销毁'),
          backgroundColor: Colors.deepPurple,
        ),
      );
    }
  }

  void _triggerExplosionAnimation() {
    setState(() {
      _particles.clear();
      // Generate 60 glowing sparks flying outwards
      for (int i = 0; i < 60; i++) {
        final double angle = _random.nextDouble() * 2 * pi;
        final double speed = _random.nextDouble() * 5 + 3;
        _particles.add(
          ExplosionParticle(
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            color: Colors.purpleAccent.withOpacity(0.8 + _random.nextDouble() * 0.2),
            size: _random.nextDouble() * 4 + 2,
          ),
        );
      }
    });
    _explosionController.forward(from: 0.0);
  }

  void _onKeyPress(String val) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += val;
      _unlockError = '';
    });

    if (_pin.length == 4) {
      if (_pin == _correctPin) {
        _triggerExplosionAnimation();
        // Sync abyss rule book sources
        ref.read(novelProvider.notifier).syncAbyss();
        
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _isUnlocked = true;
            });
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _pin = '';
              _unlockError = '密码错误，阻断访问';
            });
          }
        });
      }
    }
  }

  void _onDeletePress() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return _buildLockScreen();
    }
    return _buildChamberMainScreen();
  }

  // ==========================================
  // 🔐 1. Glowing Passcode PIN Entry Screen
  // ==========================================
  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF06030F),
      body: Stack(
        children: [
          // Background floating particle stream simulation
          Positioned.fill(
            child: CustomPaint(
              painter: ParticleExplosionPainter(
                particles: _particles,
                progress: _explosionController.value,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(
                  Icons.vpn_key_rounded,
                  size: 48,
                  color: Colors.purpleAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  '🌊 进入「深渊密室」',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '专属自愈私有书源及物理防窥护航已就绪',
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
                const SizedBox(height: 32),
                
                // PIN dots indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isFilled ? Colors.purpleAccent : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFilled ? Colors.purpleAccent : Colors.white24,
                          width: 2,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (_unlockError.isNotEmpty)
                  Text(
                    _unlockError,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                const Spacer(),
                
                // Keyboard Grid
                _buildPinKeyboard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinKeyboard() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '删除']
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((k) {
              if (k.isEmpty) return const SizedBox(width: 60, height: 60);

              final isAction = k == '删除';
              return Container(
                margin: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () {
                    if (isAction) {
                      _onDeletePress();
                    } else {
                      _onKeyPress(k);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          k,
                          style: TextStyle(
                            fontSize: isAction ? 13 : 20,
                            fontWeight: FontWeight.bold,
                            color: isAction ? Colors.purpleAccent : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // 👻 2. Unlocked Chamber Main Screen view
  // ==========================================
  Widget _buildChamberMainScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.shield_rounded, color: Colors.purpleAccent),
          onPressed: () {
            // Lock and pop back out
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '🌌 深渊密室 (Abyss)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purpleAccent,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.purpleAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NovelSearchScreen(inAbyss: true),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Dark ambient neon flows
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF040209),
                    Color(0xFF090518),
                    Color(0xFF030107),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top status warning
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.security_rounded, color: Colors.purpleAccent, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🔒 安全视窗与摇晃自锁开启中 · 摇一摇设备瞬时自锁退出',
                          style: TextStyle(color: Colors.purpleAccent, fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Toggle view tabs
                _buildTabBar(),
                
                // Scrollable main lists
                Expanded(
                  child: _activeTab == 0
                      ? NovelShelfTab(
                          inAbyss: true,
                          onOpenSearch: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NovelSearchScreen(inAbyss: true),
                              ),
                            );
                          },
                        )
                      : BookOasisTab(
                          inAbyss: true,
                          onSearchTriggered: (query) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NovelSearchScreen(
                                  inAbyss: true,
                                  initialQuery: query,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
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
                  color: _activeTab == 0 ? Colors.purple.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '📚 密室藏书阁',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.normal,
                    color: _activeTab == 0 ? Colors.purpleAccent : Colors.white60,
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
                  color: _activeTab == 1 ? Colors.purple.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '🔮 密室绿洲',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.normal,
                    color: _activeTab == 1 ? Colors.purpleAccent : Colors.white60,
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

class ExplosionParticle {
  double x = 180;
  double y = 300;
  final double vx;
  final double vy;
  final Color color;
  final double size;

  ExplosionParticle({
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class ParticleExplosionPainter extends CustomPainter {
  final List<ExplosionParticle> particles;
  final double progress;

  ParticleExplosionPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1.0) return;
    
    // Draw all active sparks
    for (final p in particles) {
      final double posX = p.x + p.vx * progress * 80;
      final double posY = p.y + p.vy * progress * 80;
      
      final paint = Paint()
        ..color = p.color.withOpacity((1.0 - progress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(posX, posY), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
