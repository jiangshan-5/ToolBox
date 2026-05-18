import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/provider/tools_provider.dart';

class RandomizerScreen extends ConsumerStatefulWidget {
  const RandomizerScreen({super.key});

  @override
  ConsumerState<RandomizerScreen> createState() => _RandomizerScreenState();
}

class _RandomizerScreenState extends ConsumerState<RandomizerScreen> {
  int _result = 0;
  final _random = Random();
  bool _isGenerating = false;

  /// Trigger number generation and log execution metrics to database
  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
    });

    final stopwatch = Stopwatch()..start();

    // Subtle delay to simulate physical wheel spinning / tactile feel
    await Future.delayed(const Duration(milliseconds: 300));
    
    final generatedVal = _random.nextInt(100) + 1;
    stopwatch.stop();

    setState(() {
      _result = generatedVal;
      _isGenerating = false;
    });

    // Fire-and-forget telemetry logging to backend database
    ref.read(toolsAnalyticsProvider).logUsage(
      toolKey: 'randomizer',
      parameters: {
        'min': 1,
        'max': 100,
        'result': generatedVal,
      },
      status: 'success',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('随机选择生成器', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '您生成的随机数字是', 
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isGenerating
                          ? const CircularProgressIndicator(color: Colors.orangeAccent)
                          : Text(
                              '$_result',
                              style: const TextStyle(
                                fontSize: 72, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.orangeAccent,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: _isGenerating ? null : _generate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 5,
                    ),
                    child: const Text(
                      '生 成 数 字', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
