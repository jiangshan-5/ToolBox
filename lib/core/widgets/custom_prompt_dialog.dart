import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_card.dart';
import 'dynamic_effects.dart';

/// Supported types of custom prompt dialogs
enum PromptDialogType {
  info,
  success,
  warning,
  error,
  confirm,
  input,
  loading,
  custom,
}

/// Configuration class for automatically rendering input fields inside the dialog
class CustomPromptTextField {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;

  const CustomPromptTextField({
    required this.label,
    required this.hint,
    this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });
}

/// Custom dialog action button configuration
class CustomDialogAction {
  final String text;
  final bool isDestructive;
  final bool isPrimary;
  final Function(BuildContext context, List<String> textValues)? onPressed;

  const CustomDialogAction({
    required this.text,
    this.isDestructive = false,
    this.isPrimary = true,
    this.onPressed,
  });
}

class CustomPromptDialog extends StatefulWidget {
  final PromptDialogType type;
  final dynamic title; // Can be String or Widget
  final dynamic message; // Can be String or Widget
  final IconData? icon;
  final Widget? iconWidget;
  final Widget? content;
  final List<CustomPromptTextField>? textFields;
  final List<CustomDialogAction>? actions;
  final Color? glowColor;

  const CustomPromptDialog({
    super.key,
    required this.type,
    this.title,
    this.message,
    this.icon,
    this.iconWidget,
    this.content,
    this.textFields,
    this.actions,
    this.glowColor,
  });

  /// Master static helper to show the dialog with customized transitions
  static Future<T?> show<T>(
    BuildContext context, {
    required PromptDialogType type,
    dynamic title,
    dynamic message,
    IconData? icon,
    Widget? iconWidget,
    Widget? content,
    List<CustomPromptTextField>? textFields,
    List<CustomDialogAction>? actions,
    Color? glowColor,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible && type != PromptDialogType.loading,
      barrierLabel: 'Dismiss dialog',
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: CustomPromptDialog(
              type: type,
              title: title,
              message: message,
              icon: icon,
              iconWidget: iconWidget,
              content: content,
              textFields: textFields,
              actions: actions,
              glowColor: glowColor,
            ),
          ),
        );
      },
    );
  }

  /// Helper to show a premium error dialog with built-in copy error details option
  static Future<void> showError(
    BuildContext context, {
    required String message,
    String title = '出错了',
    IconData icon = Icons.error_outline_rounded,
    VoidCallback? onConfirm,
    String confirmText = '确定',
    bool showCopyButton = true,
  }) {
    return show<void>(
      context: context,
      type: PromptDialogType.error,
      title: title,
      message: message,
      icon: icon,
      barrierDismissible: true,
      actions: [
        if (showCopyButton)
          CustomDialogAction(
            text: '复制详情',
            isPrimary: false,
            onPressed: (ctx, _) {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('错误详情已复制到剪贴板！'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        CustomDialogAction(
          text: confirmText,
          isDestructive: true,
          onPressed: (ctx, _) {
            Navigator.pop(ctx);
            onConfirm?.call();
          },
        ),
      ],
    );
  }

  /// Helper to show a premium success dialog
  static Future<void> showSuccess(
    BuildContext context, {
    required String message,
    String title = '操作成功',
    IconData icon = Icons.check_circle_outline_rounded,
    VoidCallback? onConfirm,
    String confirmText = '太棒了',
  }) {
    return show<void>(
      context: context,
      type: PromptDialogType.success,
      title: title,
      message: message,
      icon: icon,
      actions: [
        CustomDialogAction(
          text: confirmText,
          isPrimary: true,
          onPressed: (ctx, _) {
            Navigator.pop(ctx);
            onConfirm?.call();
          },
        ),
      ],
    );
  }

  /// Helper to show a confirm dialog (YES/NO)
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String message,
    required String title,
    IconData icon = Icons.help_outline_rounded,
    String confirmText = '确认',
    String cancelText = '取消',
    bool isDestructive = false,
  }) {
    return show<bool>(
      context: context,
      type: PromptDialogType.confirm,
      title: title,
      message: message,
      icon: icon,
      actions: [
        CustomDialogAction(
          text: cancelText,
          isPrimary: false,
          onPressed: (ctx, _) => Navigator.pop(ctx, false),
        ),
        CustomDialogAction(
          text: confirmText,
          isDestructive: isDestructive,
          isPrimary: true,
          onPressed: (ctx, _) => Navigator.pop(ctx, true),
        ),
      ],
    );
  }

  /// Helper to show a text input dialog
  static Future<List<String>?> showInput(
    BuildContext context, {
    required String title,
    required List<CustomPromptTextField> textFields,
    String? message,
    IconData icon = Icons.edit_note_rounded,
    String confirmText = '提交',
    String cancelText = '取消',
  }) {
    return show<List<String>>(
      context: context,
      type: PromptDialogType.input,
      title: title,
      message: message,
      icon: icon,
      textFields: textFields,
      actions: [
        CustomDialogAction(
          text: cancelText,
          isPrimary: false,
          onPressed: (ctx, _) => Navigator.pop(ctx, null),
        ),
        CustomDialogAction(
          text: confirmText,
          isPrimary: true,
          onPressed: (ctx, values) => Navigator.pop(ctx, values),
        ),
      ],
    );
  }

  /// Helper to show an un-dismissible loading dialog
  static Future<void> showLoading(
    BuildContext context, {
    String message = '请稍候...',
    String title = '正在处理',
  }) {
    return show<void>(
      context: context,
      type: PromptDialogType.loading,
      title: title,
      message: message,
      barrierDismissible: false,
    );
  }

  @override
  State<CustomPromptDialog> createState() => _CustomPromptDialogState();
}

class _CustomPromptDialogState extends State<CustomPromptDialog> {
  late final List<TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = widget.textFields
            ?.map((tf) => tf.controller ?? TextEditingController())
            .toList() ??
        [];
  }

  @override
  void dispose() {
    if (widget.textFields != null) {
      for (var i = 0; i < widget.textFields!.length; i++) {
        if (widget.textFields![i].controller == null) {
          _controllers[i].dispose();
        }
      }
    }
    super.dispose();
  }

  Color _getThemeColor(BuildContext context) {
    if (widget.glowColor != null) return widget.glowColor!;
    switch (widget.type) {
      case PromptDialogType.error:
        return Colors.redAccent.shade400;
      case PromptDialogType.success:
        return Colors.emerald.shade400;
      case PromptDialogType.warning:
        return Colors.amber.shade500;
      case PromptDialogType.info:
        return Colors.indigoAccent.shade200;
      case PromptDialogType.confirm:
        return Colors.purpleAccent.shade200;
      case PromptDialogType.input:
        return Colors.deepPurpleAccent.shade200;
      case PromptDialogType.loading:
        return Colors.cyanAccent.shade400;
      case PromptDialogType.custom:
        return Colors.deepPurpleAccent.shade100;
    }
  }

  IconData _getDefaultIcon() {
    switch (widget.type) {
      case PromptDialogType.error:
        return Icons.error_outline_rounded;
      case PromptDialogType.success:
        return Icons.check_circle_outline_rounded;
      case PromptDialogType.warning:
        return Icons.warning_amber_rounded;
      case PromptDialogType.info:
        return Icons.info_outline_rounded;
      case PromptDialogType.confirm:
        return Icons.help_outline_rounded;
      case PromptDialogType.input:
        return Icons.edit_note_rounded;
      case PromptDialogType.loading:
        return Icons.hourglass_empty_rounded;
      case PromptDialogType.custom:
        return Icons.lightbulb_outline_rounded;
    }
  }

  Widget _buildHeaderIcon(Color themeColor) {
    if (widget.iconWidget != null) {
      return widget.iconWidget!;
    }

    final iconData = widget.icon ?? _getDefaultIcon();

    final mainIconWidget = Icon(
      iconData,
      size: 34,
      color: Colors.white,
    );

    Widget animatedIcon;
    if (widget.type == PromptDialogType.loading) {
      animatedIcon = _RotatingWidget(
        child: Icon(
          Icons.sync_rounded,
          size: 34,
          color: Colors.white,
        ),
      );
    } else if (widget.type == PromptDialogType.success) {
      animatedIcon = _PulseIconWidget(child: mainIconWidget);
    } else {
      animatedIcon = mainIconWidget;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: themeColor.withOpacity(0.12),
        border: Border.all(
          color: themeColor.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: animatedIcon,
    );
  }

  Widget _buildTextField(CustomPromptTextField tf, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextFormField(
        controller: controller,
        obscureText: tf.isPassword,
        keyboardType: tf.keyboardType,
        maxLines: tf.maxLines,
        validator: tf.validator,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: tf.label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
          hintText: tf.hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 13,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.02),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _getThemeColor(context).withOpacity(0.8),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.redAccent.shade200,
              width: 1.0,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.redAccent.shade200,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context) {
    if (widget.type == PromptDialogType.loading) {
      return [];
    }

    final themeColor = _getThemeColor(context);

    if (widget.type == PromptDialogType.confirm || widget.type == PromptDialogType.input) {
      return [
        CustomDialogAction(
          text: '取消',
          isPrimary: false,
          onPressed: (ctx, _) => Navigator.pop(ctx, null),
        ),
        CustomDialogAction(
          text: '确定',
          isPrimary: true,
          onPressed: (ctx, values) => Navigator.pop(ctx, widget.type == PromptDialogType.input ? values : true),
        ),
      ].map((act) => _buildActionButton(act)).toList();
    }

    // Default for info/success/error/warning
    return [
      CustomDialogAction(
        text: '确定',
        isPrimary: true,
        onPressed: (ctx, _) => Navigator.pop(ctx),
      ),
    ].map((act) => _buildActionButton(act)).toList();
  }

  Widget _buildActionButton(CustomDialogAction action) {
    final themeColor = _getThemeColor(context);

    BoxDecoration decoration;
    TextStyle textStyle;

    if (action.isPrimary) {
      final gradientColors = action.isDestructive
          ? [Colors.redAccent.shade700, Colors.orangeAccent.shade700]
          : [themeColor, themeColor.withBlue(220)];

      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (action.isDestructive ? Colors.redAccent : themeColor)
                .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
      textStyle = const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14.5,
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
        color: Colors.white.withOpacity(0.04),
      );
      textStyle = TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontWeight: FontWeight.bold,
        fontSize: 14.5,
      );
    }

    return Expanded(
      child: ScaleOnTap(
        onTap: () {
          if (_formKey.currentState?.validate() ?? true) {
            final values = _controllers.map((c) => c.text).toList();
            if (action.onPressed != null) {
              action.onPressed!(context, values);
            } else {
              Navigator.pop(context, widget.type == PromptDialogType.input ? values : true);
            }
          }
        },
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: decoration,
          child: Text(action.text, style: textStyle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor(context);
    final actionsList = widget.actions?.map((act) => _buildActionButton(act)).toList() ??
        _buildDefaultActions(context);

    final showCloseButton = widget.type != PromptDialogType.loading &&
        widget.type != PromptDialogType.confirm &&
        widget.type != PromptDialogType.input;

    return Theme(
      data: ThemeData.dark(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 40.0,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          child: GlassCard(
            glowColor: themeColor,
            child: Stack(
              children: [
                // Abstract background soft neon circle
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.12),
                          blurRadius: 36,
                          spreadRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 30.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        Center(
                          child: _buildHeaderIcon(themeColor),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        if (widget.title != null) ...[
                          Center(
                            child: widget.title is Widget
                                ? widget.title
                                : Text(
                                    widget.title.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Message body
                        if (widget.message != null) ...[
                          Center(
                            child: widget.message is Widget
                                ? widget.message
                                : Text(
                                    widget.message.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 13.5,
                                      height: 1.5,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Dynamically generated Input Text Fields
                        if (widget.textFields != null &&
                            widget.textFields!.isNotEmpty) ...[
                          ...List.generate(widget.textFields!.length, (index) {
                            return _buildTextField(
                              widget.textFields![index],
                              _controllers[index],
                            );
                          }),
                          const SizedBox(height: 10),
                        ],

                        // Custom injected Content widget
                        if (widget.content != null) ...[
                          widget.content!,
                          const SizedBox(height: 20),
                        ],

                        // Action Buttons Layout
                        if (actionsList.isNotEmpty) ...[
                          Row(
                            children: [
                              for (var i = 0; i < actionsList.length; i++) ...[
                                if (i > 0) const SizedBox(width: 12),
                                actionsList[i],
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (showCloseButton)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Continuous rotating widget for loading states
class _RotatingWidget extends StatefulWidget {
  final Widget child;
  const _RotatingWidget({required this.child});

  @override
  State<_RotatingWidget> createState() => _RotatingWidgetState();
}

class _RotatingWidgetState extends State<_RotatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: widget.child,
    );
  }
}

/// Subtle pulse scaling animation for positive success feedback
class _PulseIconWidget extends StatefulWidget {
  final Widget child;
  const _PulseIconWidget({required this.child});

  @override
  State<_PulseIconWidget> createState() => _PulseIconWidgetState();
}

class _PulseIconWidgetState extends State<_PulseIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}
