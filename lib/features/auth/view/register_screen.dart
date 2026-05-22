import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_background.dart';
import '../../../core/widgets/dynamic_effects.dart';
import '../provider/auth_provider.dart';
import '../../../core/widgets/server_config_dialog.dart';

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
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入正确的邮箱地址'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    final message = await ref.read(authProvider.notifier).sendRegisterCode(email);

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_rounded, color: Colors.cyanAccent),
            tooltip: '服务器配置',
            onPressed: () => ServerConfigDialog.show(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: DynamicBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                glowColor: Colors.deepPurpleAccent,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '创建账户',
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '立即注册，开启您的高级工具箱', 
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.02),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Colors.cyanAccent, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  "开发测试与真机联调提示",
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "1. 📱 真机测试请点击右上角 🌐 图标配置电脑局域网 IP（如 http://192.168.x.x:8000）以连接服务。",
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "2. 🔑 开发调试模式下（SMTP未配置），输入万能验证码 '000000' 即可直接注册成功。",
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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
                            width: 120,
                            height: 56,
                            child: ScaleOnTap(
                              onTap: (_secondsRemaining > 0 || _isSendingCode) ? null : _sendVerificationCode,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.06),
                                  ),
                                  color: (_secondsRemaining > 0 || _isSendingCode)
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.deepPurpleAccent.withOpacity(0.15),
                                ),
                                alignment: Alignment.center,
                                child: _isSendingCode
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _secondsRemaining > 0
                                            ? '${_secondsRemaining}s'
                                            : '获取验证码',
                                        style: TextStyle(
                                          color: (_secondsRemaining > 0 || _isSendingCode)
                                              ? Colors.white38
                                              : Colors.white,
                                          fontSize: 14,
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
                      _buildRegisterButton(),
                      const SizedBox(height: 28),
                      ScaleOnTap(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "已有账户？立即登录", 
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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

  Widget _buildRegisterButton() {
    return ScaleOnTap(
      onTap: _isLoading ? null : _handleRegister,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.deepPurpleAccent,
              Colors.purpleAccent.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isLoading 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ) 
            : const Text(
                '注 册', 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
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

    await ref.read(authProvider.notifier).register(email, password, code);
    
    if (mounted) {
      final error = ref.read(authProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error), 
            backgroundColor: Colors.redAccent,
          ),
        );
      } else {
        // Pop back to login screen on successful registration
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_isFocused ? 0.07 : 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused 
              ? Colors.deepPurpleAccent.withOpacity(0.8) 
              : Colors.white.withOpacity(0.06),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (_isFocused)
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.20),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        cursorColor: Colors.deepPurpleAccent,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _isFocused ? Colors.deepPurpleAccent : Colors.white60,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: _isFocused ? Colors.deepPurpleAccent : Colors.white54,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
