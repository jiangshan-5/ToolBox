import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:math';

import '../../../features/dashboard/provider/tools_provider.dart';

class PasswordGeneratorScreen extends ConsumerStatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  ConsumerState<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState
    extends ConsumerState<PasswordGeneratorScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get textColor => isDark ? Colors.white : Colors.black87;

  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;

  Color get faintTextColor => isDark ? Colors.white38 : Colors.black38;

  Color get borderDividerColor =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  double _passwordLength = 16.0;

  bool _includeUppercase = true;

  bool _includeLowercase = true;

  bool _includeNumbers = true;

  bool _includeSymbols = true;

  String _generatedPassword = '';

  String _strengthLabel = '极强 (Ultra)';

  Color _strengthColor = Colors.cyanAccent;

  double _strengthProgress = 1.0;

  @override
  void initState() {
    super.initState();

    _generatePassword();
  }

  void _generatePassword() {
    const uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    const lowercaseChars = 'abcdefghijklmnopqrstuvwxyz';

    const numberChars = '0123456789';

    const symbolChars = '!@#\$%^&*()_+~`|}{[]:;?><,./-=';

    String allowedChars = '';

    if (_includeUppercase) allowedChars += uppercaseChars;

    if (_includeLowercase) allowedChars += lowercaseChars;

    if (_includeNumbers) allowedChars += numberChars;

    if (_includeSymbols) allowedChars += symbolChars;

    if (allowedChars.isEmpty) {
      setState(() {
        _generatedPassword = '';

        _strengthLabel = '无选择';

        _strengthColor = Colors.grey;

        _strengthProgress = 0.0;
      });

      return;
    }

    final Random random = Random.secure();

    final int length = _passwordLength.toInt();

    List<String> passwordList = [];

    // Ensure at least one of each selected category is included

    if (_includeUppercase) {
      passwordList.add(uppercaseChars[random.nextInt(uppercaseChars.length)]);
    }

    if (_includeLowercase) {
      passwordList.add(lowercaseChars[random.nextInt(lowercaseChars.length)]);
    }

    if (_includeNumbers) {
      passwordList.add(numberChars[random.nextInt(numberChars.length)]);
    }

    if (_includeSymbols) {
      passwordList.add(symbolChars[random.nextInt(symbolChars.length)]);
    }

    while (passwordList.length < length) {
      passwordList.add(allowedChars[random.nextInt(allowedChars.length)]);
    }

    passwordList.shuffle(random);

    final password = passwordList.join();

    // Calculate password strength based on length & configuration

    double strength = 0.0;

    if (_includeUppercase) strength += 0.2;

    if (_includeLowercase) strength += 0.2;

    if (_includeNumbers) strength += 0.2;

    if (_includeSymbols) strength += 0.25;

    strength += (length / 32) * 0.15; // length bonus

    String label;

    Color color;

    if (strength < 0.4) {
      label = '弱 (Weak)';

      color = Colors.redAccent;
    } else if (strength < 0.6) {
      label = '一般 (Medium)';

      color = Colors.amberAccent;
    } else if (strength < 0.8) {
      label = '强 (Strong)';

      color = Colors.greenAccent;
    } else {
      label = '极其安全 (Safe)';

      color = Colors.cyanAccent;
    }

    setState(() {
      _generatedPassword = password;

      _strengthLabel = label;

      _strengthColor = color;

      _strengthProgress = strength.clamp(0.0, 1.0);
    });

    // Telemetry: log password generation event

    try {
      ref
          .read(toolsAnalyticsProvider)
          .logUsage(
            toolKey: 'password_generator',

            parameters: {
              'length': length,

              'has_uppercase': _includeUppercase,

              'has_lowercase': _includeLowercase,

              'has_numbers': _includeNumbers,

              'has_symbols': _includeSymbols,

              'strength': label,
            },

            status: 'success',

            durationMs: 0,
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        elevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white70 : Colors.black87,
          ),

          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          '密码生成与强度分析',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),

      body: Stack(
        children: [
          // Theme Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0C091F),
                        const Color(0xFF140F2D),
                        const Color(0xFF06050C),
                      ]
                    : [
                        primaryColor.withOpacity(0.06),
                        const Color(0xFFFAF9FF),
                        Colors.white,
                      ],

                begin: Alignment.topLeft,

                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

              children: [
                // Display Password Box
                Text(
                  '🔑 生成的安全密码',

                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),

                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.02)
                        : Colors.black.withOpacity(0.03),

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: borderDividerColor),
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _generatedPassword.isEmpty
                              ? '请选择下方选项生成密码'
                              : _generatedPassword,

                          style: TextStyle(
                            color: textColor,

                            fontSize: 18,

                            fontWeight: FontWeight.bold,

                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          color: primaryColor,
                          size: 20,
                        ),

                        onPressed: _generatedPassword.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(
                                  ClipboardData(text: _generatedPassword),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('安全密码已成功复制'),

                                    backgroundColor: isDark
                                        ? const Color(0xFF0F0C29)
                                        : Theme.of(context).colorScheme.surfaceContainer,
                                  ),
                                );
                              },
                      ),

                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: subTextColor,
                          size: 20,
                        ),

                        onPressed: _generatePassword,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Strength Meter
                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.015)
                        : Colors.black.withOpacity(0.02),

                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: borderDividerColor),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Text(
                            '🛡️ 密码防护强度等级',

                            style: TextStyle(color: subTextColor, fontSize: 12),
                          ),

                          Text(
                            _strengthLabel,

                            style: TextStyle(
                              color: _strengthColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),

                        child: LinearProgressIndicator(
                          value: _strengthProgress,

                          backgroundColor: isDark ? Colors.white10 : Colors.black12,

                          valueColor: AlwaysStoppedAnimation<Color>(
                            _strengthColor,
                          ),

                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Configuration Panel
                Text(
                  '⚙️ 自定义参数配置',

                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.02)
                        : Colors.black.withOpacity(0.03),

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: borderDividerColor),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Text(
                            '密码长度',

                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Text(
                            '${_passwordLength.toInt()} 位',

                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Slider(
                        value: _passwordLength,

                        min: 6,

                        max: 32,

                        activeColor: primaryColor,

                        inactiveColor: isDark ? Colors.white10 : Colors.black12,

                        onChanged: (val) {
                          setState(() {
                            _passwordLength = val;
                          });

                          _generatePassword();
                        },
                      ),

                      Divider(color: borderDividerColor),

                      _buildConfigToggle('包含大写字母 (A-Z)', _includeUppercase, (
                        val,
                      ) {
                        setState(() => _includeUppercase = val);

                        _generatePassword();
                      }),

                      _buildConfigToggle('包含小写字母 (a-z)', _includeLowercase, (
                        val,
                      ) {
                        setState(() => _includeLowercase = val);

                        _generatePassword();
                      }),

                      _buildConfigToggle('包含数字 (0-9)', _includeNumbers, (val) {
                        setState(() => _includeNumbers = val);

                        _generatePassword();
                      }),

                      _buildConfigToggle('包含特殊符号 (!@#...)', _includeSymbols, (
                        val,
                      ) {
                        setState(() => _includeSymbols = val);

                        _generatePassword();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return SwitchListTile(
      title: Text(label, style: TextStyle(color: subTextColor, fontSize: 12.5)),

      value: value,

      activeThumbColor: primaryColor,

      activeTrackColor: primaryColor.withOpacity(0.2),

      inactiveThumbColor: isDark ? Colors.white30 : Colors.black26,

      inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,

      contentPadding: EdgeInsets.zero,

      onChanged: onChanged,
    );
  }
}
