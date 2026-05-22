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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    _isLoading = authState.isLoading;

    return Scaffold(
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
                      const SizedBox(height: 40),
                      _CyberInput(
                        controller: _emailController,
                        label: '邮箱地址',
                        icon: Icons.email_outlined,
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

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写完整的账号和密码'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    await ref.read(authProvider.notifier).register(email, password);
    
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
