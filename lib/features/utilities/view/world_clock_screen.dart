import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../features/dashboard/provider/tools_provider.dart';

class WorldClockScreen extends ConsumerStatefulWidget {
  const WorldClockScreen({super.key});

  @override
  ConsumerState<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends ConsumerState<WorldClockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  // Pomodoro Timer States
  Timer? _pomodoroTimer;
  int _secondsRemaining = 1500; // 25 minutes
  bool _isTimerRunning = false;
  bool _isBreakTime = false;
  int _totalCompletedCycles = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Update Clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clockTimer.cancel();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  // Pomodoro Controllers
  void _startTimer() {
    if (_isTimerRunning) return;
    setState(() {
      _isTimerRunning = true;
    });

    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _handleTimerCompletion();
      }
    });
  }

  void _pauseTimer() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = _isBreakTime ? 300 : 1500;
    });
  }

  void _handleTimerCompletion() {
    _pomodoroTimer?.cancel();
    final bool wasWorkCycle = !_isBreakTime;
    setState(() {
      _isTimerRunning = false;
      if (!_isBreakTime) {
        // Finished a work cycle!
        _isBreakTime = true;
        _secondsRemaining = 300; // 5 mins break
        _totalCompletedCycles++;
      } else {
        // Finished a break cycle!
        _isBreakTime = false;
        _secondsRemaining = 1500; // 25 mins work
      }
    });

    // Log telemetry when a pomodoro WORK cycle completes
    if (wasWorkCycle) {
      try {
        ref
            .read(toolsAnalyticsProvider)
            .logUsage(
              toolKey: 'world_clock',
              parameters: {
                'event': 'pomodoro_cycle_complete',
                'total_cycles': _totalCompletedCycles,
              },
              status: 'success',
              durationMs: 1500000, // 25 minutes in ms
            );
      } catch (_) {}
    }

    // Notify user with standard snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBreakTime ? '🎉 专注时间结束！进入 5 分钟小憩吧' : '💪 休息结束！开启下一轮专注工作',
        ),
        backgroundColor: Colors.purpleAccent,
      ),
    );
  }

  String _formatPomodoroTime() {
    final int minutes = _secondsRemaining ~/ 60;
    final int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '时区对照与极智番茄钟',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
          tabs: const [
            Tab(text: '🌐 世界时区对照'),
            Tab(text: '⏱️ 极智专注番茄钟'),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0C091F),
                        const Color(0xFF140F2D),
                        const Color(0xFF06050C),
                      ]
                    : [
                        primaryColor.withOpacity(0.06),
                        const Color(0xFFFAF9FF),
                        Colors.white,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [_buildWorldClockTab(), _buildPomodoroTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldClockTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildClockItem('北京 (UTC+8)', _now, 0),
        _buildClockItem('东京 (UTC+9)', _now, 1),
        _buildClockItem('伦敦 (UTC+1)', _now, -7),
        _buildClockItem('纽约 (UTC-4)', _now, -12),
        _buildClockItem('悉尼 (UTC+10)', _now, 2),
      ],
    );
  }

  Widget _buildClockItem(String location, DateTime baseTime, int offsetHours) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black38;
    final Color borderDividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final DateTime targetTime = baseTime.toUtc().add(
      Duration(hours: offsetHours),
    );

    final String hourStr = targetTime.hour.toString().padLeft(2, '0');
    final String minuteStr = targetTime.minute.toString().padLeft(2, '0');
    final String secondStr = targetTime.second.toString().padLeft(2, '0');
    final String timeStr = '$hourStr:$minuteStr:$secondStr';

    final String yearStr = targetTime.year.toString();
    final String monthStr = targetTime.month.toString().padLeft(2, '0');
    final String dayStr = targetTime.day.toString().padLeft(2, '0');
    final String dateStr = '$yearStr/$monthStr/$dayStr';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderDividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: TextStyle(color: faintTextColor, fontSize: 11),
              ),
            ],
          ),
          Text(
            timeStr,
            style: TextStyle(
              color: primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroTab() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final double progress = _secondsRemaining / (_isBreakTime ? 300 : 1500);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Timer View
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isBreakTime ? Colors.green : primaryColor,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isBreakTime ? '休息中...' : '专注中...',
                    style: TextStyle(
                      color: _isBreakTime
                          ? Colors.green
                          : primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatPomodoroTime(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Total Stats
          Text(
            '今日已成功专注周期: $_totalCompletedCycles 轮',
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
          const SizedBox(height: 30),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundButton(
                Icons.refresh_rounded,
                _resetTimer,
                isDark ? Colors.white38 : Colors.black45,
              ),
              const SizedBox(width: 24),
              _buildRoundButton(
                _isTimerRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                _isTimerRunning ? _pauseTimer : _startTimer,
                _isBreakTime ? Colors.green : primaryColor,
                isLarge: true,
              ),
              const SizedBox(width: 24),
              _buildRoundButton(
                Icons.skip_next_rounded,
                _handleTimerCompletion,
                isDark ? Colors.white38 : Colors.black45,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(
    IconData icon,
    VoidCallback onTap,
    Color color, {
    bool isLarge = false,
  }) {
    final size = isLarge ? 64.0 : 48.0;
    final iconSize = isLarge ? 32.0 : 20.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}
