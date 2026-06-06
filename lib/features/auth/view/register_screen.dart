import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_background.dart';
import '../../../core/widgets/dynamic_effects.dart';
import '../provider/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  bool _isSendingCode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入格式正确的邮箱地址'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    final message = await ref
        .read(authProvider.notifier)
        .sendRegisterCode(email);

    if (!mounted) return;

    setState(() {
      _isSendingCode = false;
    });

    if (mounted) {
      final authState = ref.read(authProvider);
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
          ),
        );
        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error ?? '发送验证码失败'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    _isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: colors.onSurface),
      ),
      body: DynamicBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                glowColor: colors.primary,
                borderRadius: 28.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minimalist Glowing Logo Indicator
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '创建账户',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '注册您的智能云端数字沙盒账户',
                        style: TextStyle(
                          color: colors.onSurface.withOpacity(0.55),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _CyberInput(
                        controller: _emailController,
                        label: '邮箱地址',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _CyberInput(
                              controller: _codeController,
                              label: '验证码',
                              icon: Icons.verified_user_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            height: 50,
                            child: ScaleOnTap(
                              onTap: (_secondsRemaining > 0 || _isSendingCode)
                                  ? null
                                  : _sendVerificationCode,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _secondsRemaining > 0
                                        ? Colors.transparent
                                        : (isDark
                                            ? Colors.white.withOpacity(0.06)
                                            : Colors.black.withOpacity(0.08)),
                                  ),
                                  color: (_secondsRemaining > 0 || _isSendingCode)
                                      ? (isDark
                                          ? Colors.white.withOpacity(0.04)
                                          : Colors.black.withOpacity(0.04))
                                      : colors.secondary.withOpacity(0.08),
                                ),
                                alignment: Alignment.center,
                                child: _isSendingCode
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: colors.secondary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _secondsRemaining > 0
                                            ? '${_secondsRemaining}s'
                                            : '获取验证码',
                                        style: TextStyle(
                                          color: (_secondsRemaining > 0 || _isSendingCode)
                                              ? colors.onSurface.withOpacity(0.35)
                                              : colors.secondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CyberInput(
                        controller: _passwordController,
                        label: '密码',
                        icon: Icons.lock_outline,
                        obscure: true,
                      ),
                      const SizedBox(height: 32),
                      _buildRegisterButton(colors),
                      const SizedBox(height: 24),
                      ScaleOnTap(
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "已有账户？立即登录",
                            style: TextStyle(
                              color: colors.onSurface.withOpacity(0.65),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(ColorScheme colors) {
    return ScaleOnTap(
      onTap: _isLoading ? null : _handleRegister,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [colors.primary, colors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: colors.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Text(
                '注 册',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimary,
                  letterSpacing: 3.0,
                ),
              ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty || password.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写完整的注册信息'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入格式正确的邮箱地址'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    await ref.read(authProvider.notifier).register(email, password, code);

    if (mounted) {
      final error = ref.read(authProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }
}

class _CyberInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;

  const _CyberInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
  });

  @override
  State<_CyberInput> createState() => _CyberInputState();
}

class _CyberInputState extends State<_CyberInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(_isFocused ? 0.05 : 0.02)
            : Colors.black.withOpacity(_isFocused ? 0.04 : 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? colors.primary.withOpacity(0.8)
              : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.06)),
          width: _isFocused ? 1.2 : 1.0,
        ),
        boxShadow: [
          if (_isFocused)
            BoxShadow(
              color: colors.primary.withOpacity(0.12),
              blurRadius: 10,
              spreadRadius: 0.5,
            ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscure,
        style: TextStyle(color: colors.onSurface, fontSize: 14.5),
        cursorColor: colors.primary,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _isFocused
                ? colors.primary
                : colors.onSurface.withOpacity(0.50),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            widget.icon,
            size: 20,
            color: _isFocused
                ? colors.primary
                : colors.onSurface.withOpacity(0.40),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
