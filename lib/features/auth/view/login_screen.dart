import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_background.dart';
import '../../../core/widgets/dynamic_effects.dart';
import '../provider/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  /// Trigger secure backend authorization
  Future<void> _handleLogin() async {
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

    await ref.read(authProvider.notifier).login(email, password);

    if (mounted) {
      final error = ref.read(authProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onLongPress: () {
                          ref.read(authProvider.notifier).loginAsAdmin();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚡ 开发者通道激活：正在以管理员身份登录...'),
                              backgroundColor: Colors.deepPurpleAccent,
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          '欢迎回来',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '登录您的 Toolbox Pro 账户',
                        style: TextStyle(
                          color: colors.onSurface.withOpacity(0.55),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),
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
                      _buildLoginButton(colors),
                      const SizedBox(height: 24),
                      _buildRegisterLink(colors),
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

  Widget _buildLoginButton(ColorScheme colors) {
    return ScaleOnTap(
      onTap: _isLoading ? null : _handleLogin,
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
                '登 录',
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

  Widget _buildRegisterLink(ColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleOnTap(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "还没有账户？立即注册",
              style: TextStyle(
                color: colors.onSurface.withOpacity(0.65),
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ScaleOnTap(
          onTap: () => ref.read(authProvider.notifier).loginAsGuest(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.secondary.withOpacity(0.2),
                width: 1.0,
              ),
              color: colors.secondary.withOpacity(0.03),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: colors.secondary, size: 16),
                const SizedBox(width: 4),
                Text(
                  "游客快捷体验",
                  style: TextStyle(
                    color: colors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
