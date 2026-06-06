import 'package:flutter/material.dart';
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
import '../../../daily_board/view/daily_board_screen.dart';
import '../../../novel/view/novel_workbench_screen.dart';

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
Widget? getToolPage(String toolKey) => switch (toolKey) {
      'randomizer' => const DeferredPage(title: '高自由度决策随机沙盒', child: RandomizerScreen()),
      'unit_converter' || 'converter' => const DeferredPage(title: '物理量公式沙盒转换站', child: ConverterScreen()),
      'bmi_calculator' => const DeferredPage(title: '体征与宏量营养沙盒', child: BmiScreen()),
      'ai_chat' => const DeferredPage(title: 'AI 智能多轮对话助理', child: AiChatScreen()),
      'ai_text_processor' => const DeferredPage(title: 'AI 高级写作引擎', child: AiTextProcessorScreen()),
      'word_counter' => const DeferredPage(title: '字数与字符统计器', child: WordCounterScreen()),
      'password_generator' => const DeferredPage(title: '密码生成与强度分析', child: PasswordGeneratorScreen()),
      'world_clock' => const DeferredPage(title: '时区对照与极智番茄钟', child: WorldClockScreen()),
      'white_noise' => const DeferredPage(title: '律动呼吸与多声道白噪音', child: WhiteNoiseScreen()),
      'markdown_editor' => const DeferredPage(title: '极简 Markdown 工作站', child: MarkdownEditorScreen()),
      'led_banner' => const DeferredPage(title: 'LED 手持弹幕', child: LedBannerScreen()),
      'dev_encoder' => const DeferredPage(title: '开发者沙盒编码盒', child: DevEncoderScreen()),
      'daily_board' => const DeferredPage(title: '今日时事与卡片工坊', child: DailyBoardScreen()),
      'novel_reader' => const DeferredPage(title: '全网去噪智能小说阅读器', child: NovelWorkbenchScreen()),
      _ => null,
    };

IconData getToolIcon(String toolKey) => switch (toolKey) {
      'randomizer' => Icons.casino_rounded,
      'unit_converter' || 'converter' => Icons.swap_horiz_rounded,
      'bmi_calculator' => Icons.monitor_weight_outlined,
      'word_counter' => Icons.text_fields_rounded,
      'password_generator' => Icons.lock_reset_rounded,
      'world_clock' => Icons.alarm_rounded,
      'white_noise' => Icons.spa_rounded,
      'markdown_editor' => Icons.edit_note_rounded,
      'ai_chat' => Icons.psychology_rounded,
      'ai_text_processor' => Icons.auto_awesome_rounded,
      'led_banner' => Icons.settings_input_hdmi_rounded,
      'dev_encoder' => Icons.code_rounded,
      'daily_board' => Icons.newspaper_rounded,
      'novel_reader' => Icons.auto_stories_rounded,
      _ => Icons.build_rounded,
    };

Color getToolColor(String toolKey, BuildContext context) {
  final theme = Theme.of(context);
  final primaryColor = theme.colorScheme.primary;
  final secondaryColor = theme.colorScheme.secondary;
  return switch (toolKey) {
    'randomizer' => Colors.orangeAccent,
    'unit_converter' || 'converter' => Colors.cyanAccent,
    'bmi_calculator' => Colors.pinkAccent,
    'word_counter' => Colors.lightGreenAccent,
    'password_generator' => Colors.greenAccent,
    'world_clock' => primaryColor,
    'white_noise' => Colors.tealAccent,
    'markdown_editor' => Colors.amberAccent,
    'ai_chat' => primaryColor,
    'ai_text_processor' => Colors.amberAccent,
    'led_banner' => Colors.pinkAccent,
    'dev_encoder' => Colors.cyanAccent,
    'daily_board' => Colors.cyanAccent,
    'novel_reader' => Colors.pinkAccent,
    _ => secondaryColor,
  };
}

String getToolChineseName(String toolKey) => switch (toolKey) {
      'randomizer' => '随机选择生成器',
      'unit_converter' || 'converter' => '标准单位转换器',
      'bmi_calculator' => '健康 BMI 计算器',
      'word_counter' => '字数与字符统计器',
      'password_generator' => '密码生成与强度分析',
      'world_clock' => '多时区时钟与番茄钟',
      'white_noise' => '律动呼吸与多声道白噪音',
      'markdown_editor' => '极简 Markdown 编辑器',
      'ai_chat' => 'AI 智能多轮对话助理',
      'ai_text_processor' => 'AI 写作引擎',
      'led_banner' => 'LED 手持弹幕',
      'dev_encoder' => '开发者沙盒编码盒',
      'daily_board' => '今日热闻与卡片工坊',
      'novel_reader' => '智能去噪小说阅读器',
      _ => '常用系统工具',
    };

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
