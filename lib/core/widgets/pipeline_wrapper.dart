import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pipeline_provider.dart';
import '../../features/dashboard/view/widgets/dashboard_utils.dart';
import 'glass_card.dart';

class PipelineWrapper extends ConsumerStatefulWidget {
  final String toolKey;
  final TextEditingController controller;
  final TextEditingController? inputController;
  final Widget child;

  const PipelineWrapper({
    super.key,
    required this.toolKey,
    required this.controller,
    this.inputController,
    required this.child,
  });

  @override
  ConsumerState<PipelineWrapper> createState() => _PipelineWrapperState();
}

class _PipelineWrapperState extends ConsumerState<PipelineWrapper> {
  bool _hasInjected = false;

  void _checkAndInject(PipelineSession session) {
    if (!session.isActive) {
      if (_hasInjected) {
        setState(() {
          _hasInjected = false;
        });
      }
      return;
    }

    final currentIndex = session.currentStepIndex;
    if (currentIndex >= 0 && currentIndex < session.steps.length) {
      final currentToolKey = session.steps[currentIndex];
      if (currentToolKey == widget.toolKey) {
        if (!_hasInjected) {
          final inputVal = session.stepInputs[currentIndex] ?? '';
          if (inputVal.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              (widget.inputController ?? widget.controller).text = inputVal;
            });
          }
          setState(() {
            _hasInjected = true;
          });
        }
      } else {
        if (_hasInjected) {
          setState(() {
            _hasInjected = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pipelineSessionProvider);

    _checkAndInject(session);

    final bool isThisStepActive = session.isActive &&
        session.steps.isNotEmpty &&
        session.currentStepIndex < session.steps.length &&
        session.steps[session.currentStepIndex] == widget.toolKey;

    if (!isThisStepActive) {
      return widget.child;
    }

    final currentIndex = session.currentStepIndex;
    final totalSteps = session.steps.length;
    final toolColor = getToolColor(widget.toolKey, context);
    final toolChineseName = getToolChineseName(widget.toolKey);

    final bool isLastStep = currentIndex == totalSteps - 1;

    String nextToolText = '';
    if (!isLastStep) {
      final nextKey = session.steps[currentIndex + 1];
      nextToolText = getToolChineseName(nextKey);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;
    final actionIconColor = isDark ? Colors.white54 : Colors.black54;

    return Stack(
      children: [
        widget.child,
        // Dynamic Floating Bottom Controller Panel
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: GlassCard(
                borderColor: toolColor.withOpacity(0.3),
                glowColor: toolColor,
                borderRadius: 20,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Step Progress Indicator
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: toolColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: toolColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${currentIndex + 1}/$totalSteps',
                          style: TextStyle(
                            color: toolColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Step Information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '流水线',
                                    style: TextStyle(
                                      color: Colors.purpleAccent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    toolChineseName,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLastStep ? '🏁 终点站，点击完成' : '👉 下一步: $nextToolText',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '跳过此步',
                            icon: Icon(Icons.skip_next_rounded, color: actionIconColor, size: 20),
                            onPressed: () {
                              ref.read(pipelineSessionProvider.notifier).skipStep(context);
                            },
                          ),
                          IconButton(
                            tooltip: '终止流程',
                            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              ref.read(pipelineSessionProvider.notifier).resetSession();
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🚫 流水线已被手动终止'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              ref.read(pipelineSessionProvider.notifier).completeStep(context, widget.controller.text);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isLastStep
                                      ? [Colors.greenAccent, Colors.tealAccent]
                                      : [toolColor, toolColor.withBlue(255)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: toolColor.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                isLastStep ? '完成' : '下一步',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
