import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/glass_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../../randomizer/view/randomizer_screen.dart';
import '../../converter/view/converter_screen.dart';
import '../../bmi/view/bmi_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userEmail = ref.watch(authProvider).email ?? "User";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(userEmail),
                  const SizedBox(height: 32),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
                        
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: tools.length,
                          itemBuilder: (context, index) {
                            final tool = tools[index];
                            return GlassCard(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tool.page)),
                              borderColor: tool.color.withOpacity(0.3),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(tool.icon, size: 36, color: tool.color),
                                    Text(
                                      tool.title,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
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

  Widget _buildHeader(String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Toolbox Pro',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        Text('Welcome back, $email', style: const TextStyle(color: Colors.white60, fontSize: 16)),
      ],
    );
  }
}

class Tool {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  Tool(this.title, this.icon, this.color, this.page);
}

final List<Tool> tools = [
  Tool('Randomizer', Icons.casino, Colors.orangeAccent, const RandomizerScreen()),
  Tool('Converter', Icons.swap_horiz, Colors.cyanAccent, const ConverterScreen()),
  Tool('BMI Calc', Icons.monitor_weight, Colors.pinkAccent, const BmiScreen()),
  Tool('Notes', Icons.edit_note, Colors.lightGreenAccent, const Scaffold(body: Center(child: Text('Notes Screen Soon')))),
];
