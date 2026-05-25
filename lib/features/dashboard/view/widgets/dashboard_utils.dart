import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/widgets/deferred_page.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../randomizer/view/randomizer_screen.dart';
import '../../../converter/view/converter_screen.dart';
import '../../../bmi/view/bmi_screen.dart';
import '../../../ai/view/ai_chat_screen.dart';
import '../../../ai/view/ai_text_processor_screen.dart';
import '../../../utilities/view/word_counter_screen.dart';
import '../../../utilities/view/password_generator_screen.dart';
import '../../../utilities/view/world_clock_screen.dart';
import '../../../utilities/view/white_noise_screen.dart';
import '../../../utilities/view/markdown_editor_screen.dart';
import '../../../utilities/view/led_banner_screen.dart';
import '../../../utilities/view/dev_encoder_screen.dart';
import '../../../utilities/view/daily_board_screen.dart';

/// Elite ultra-smooth fade transition route that eliminates page entry stutters
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  FadePageRoute({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 220),
      );
}

/// Map database tool keys to compiled Flutter widget views wrapped in a deferred-transition container
Widget? getToolPage(String toolKey) {
  switch (toolKey) {
    case 'randomizer':
      return const DeferredPage(title: '高自由度决策随机沙盒', child: RandomizerScreen());
    case 'unit_converter':
    case 'converter':
      return const DeferredPage(title: '物理量公式沙盒转换站', child: ConverterScreen());
    case 'bmi_calculator':
      return const DeferredPage(title: '体征与宏量营养沙盒', child: BmiScreen());
    case 'ai_chat':
      return const DeferredPage(title: 'AI 智能多轮对话助理', child: AiChatScreen());
    case 'ai_text_processor':
      return const DeferredPage(
        title: 'AI 高级写作引擎',
        child: AiTextProcessorScreen(),
      );
    case 'word_counter':
      return const DeferredPage(title: '字数与字符统计器', child: WordCounterScreen());
    case 'password_generator':
      return const DeferredPage(
        title: '密码生成与强度分析',
        child: PasswordGeneratorScreen(),
      );
    case 'world_clock':
      return const DeferredPage(title: '时区对照与极智番茄钟', child: WorldClockScreen());
    case 'white_noise':
      return const DeferredPage(
        title: '律动呼吸与多声道白噪音',
        child: WhiteNoiseScreen(),
      );
    case 'markdown_editor':
      return const DeferredPage(
        title: '极简 Markdown 工作站',
        child: MarkdownEditorScreen(),
      );
    case 'led_banner':
      return const DeferredPage(title: 'LED 手持弹幕', child: LedBannerScreen());
    case 'dev_encoder':
      return const DeferredPage(title: '开发者沙盒编码盒', child: DevEncoderScreen());
    case 'daily_board':
      return const DeferredPage(title: '今日时事与卡片工坊', child: DailyBoardScreen());
    default:
      return null;
  }
}

IconData getToolIcon(String toolKey) {
  switch (toolKey) {
    case 'randomizer':
      return Icons.casino_rounded;
    case 'unit_converter':
    case 'converter':
      return Icons.swap_horiz_rounded;
    case 'bmi_calculator':
      return Icons.monitor_weight_outlined;
    case 'word_counter':
      return Icons.text_fields_rounded;
    case 'password_generator':
      return Icons.lock_reset_rounded;
    case 'world_clock':
      return Icons.alarm_rounded;
    case 'white_noise':
      return Icons.spa_rounded;
    case 'markdown_editor':
      return Icons.edit_note_rounded;
    case 'ai_chat':
      return Icons.psychology_rounded;
    case 'ai_text_processor':
      return Icons.auto_awesome_rounded;
    case 'led_banner':
      return Icons.settings_input_hdmi_rounded;
    case 'dev_encoder':
      return Icons.code_rounded;
    case 'daily_board':
      return Icons.newspaper_rounded;
    default:
      return Icons.build_rounded;
  }
}

Color getToolColor(String toolKey, BuildContext context) {
  final theme = Theme.of(context);
  final primaryColor = theme.colorScheme.primary;
  final secondaryColor = theme.colorScheme.secondary;
  switch (toolKey) {
    case 'randomizer':
      return Colors.orangeAccent;
    case 'unit_converter':
    case 'converter':
      return Colors.cyanAccent;
    case 'bmi_calculator':
      return Colors.pinkAccent;
    case 'word_counter':
      return Colors.lightGreenAccent;
    case 'password_generator':
      return Colors.greenAccent;
    case 'world_clock':
      return primaryColor;
    case 'white_noise':
      return Colors.tealAccent;
    case 'markdown_editor':
      return Colors.amberAccent;
    case 'ai_chat':
      return primaryColor;
    case 'ai_text_processor':
      return Colors.amberAccent;
    case 'led_banner':
      return Colors.pinkAccent;
    case 'dev_encoder':
      return Colors.cyanAccent;
    case 'daily_board':
      return Colors.cyanAccent;
    default:
      return secondaryColor;
  }
}

String getToolChineseName(String toolKey) {
  switch (toolKey) {
    case 'randomizer':
      return '随机选择生成器';
    case 'unit_converter':
    case 'converter':
      return '标准单位转换器';
    case 'bmi_calculator':
      return '健康 BMI 计算器';
    case 'word_counter':
      return '字数与字符统计器';
    case 'password_generator':
      return '密码生成与强度分析';
    case 'world_clock':
      return '多时区时钟与番茄钟';
    case 'white_noise':
      return '律动呼吸与多声道白噪音';
    case 'markdown_editor':
      return '极简 Markdown 编辑器';
    case 'ai_chat':
      return 'AI 智能多轮对话助理';
    case 'ai_text_processor':
      return 'AI 写作引擎';
    case 'led_banner':
      return 'LED 手持弹幕';
    case 'dev_encoder':
      return '开发者沙盒编码盒';
    case 'daily_board':
      return '今日热闻与卡片工坊';
    default:
      return '常用系统工具';
  }
}

String formatTime(String isoString) {
  try {
    final dateTime = DateTime.parse(isoString);
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  } catch (_) {
    return '刚刚';
  }
}

void showComingSoonDialog(BuildContext context, String toolName) {
  final theme = Theme.of(context);
  final primaryColor = theme.colorScheme.primary;
  final secondaryColor = theme.colorScheme.secondary;
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          borderColor: secondaryColor.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 56,
                  color: Colors.amberAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  toolName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '💡 功能正在全力开发中\n我们将于近期版本为您解锁这套超高强度的智能化服务，敬请期待！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('好 的'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
