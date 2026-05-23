import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/providers/api_config_provider.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../settings/provider/settings_provider.dart';
import '../../../converter/provider/converter_provider.dart';
import '../../provider/tools_provider.dart';
import 'dashboard_utils.dart';

class ProfileTabView extends ConsumerStatefulWidget {
  final String userEmail;
  final String userNickname;
  final bool isWide;

  const ProfileTabView({
    super.key,
    required this.userEmail,
    required this.userNickname,
    required this.isWide,
  });

  @override
  ConsumerState<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends ConsumerState<ProfileTabView> {
  Color get primaryColor => Theme.of(context).colorScheme.primary;
  Color get secondaryColor => Theme.of(context).colorScheme.secondary;
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;
  Color get faintTextColor => isDark ? Colors.white38 : Colors.black38;
  Color get borderDividerColor =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  Future<void> _exportData(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: primaryColor)),
    );
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.instance.get('/analytics/export');
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> healthData = data['health'] ?? [];
        final List<dynamic> aiData = data['ai'] ?? [];
        final List<List<dynamic>> csvData = [];

        csvData.add(['--- 健康监测数据 (Health Records) ---']);
        csvData.add(['时间', '体重 (kg)', '身高 (cm)', 'BMI']);
        for (var record in healthData) {
          csvData.add([
            record['recorded_at'] ?? '',
            record['weight_kg'] ?? '',
            record['height_cm'] ?? '',
            record['bmi'] ?? '',
          ]);
        }
        csvData.add([]);
        csvData.add([]);

        csvData.add(['--- AI 使用监测数据 (AI Telemetry Logs) ---']);
        csvData.add(['时间', '服务商', '模型名称', '生成词数', '节省时间 (秒)']);
        for (var log in aiData) {
          csvData.add([
            log['created_at'] ?? '',
            log['provider'] ?? '',
            log['model_name'] ?? '',
            log['words_generated'] ?? '',
            log['time_saved_seconds'] ?? '',
          ]);
        }

        final csvString = Csv().encode(csvData);

        if (kIsWeb) {
          final bytes = const Utf8Encoder().convert(csvString);
          final xFile = XFile.fromData(
            bytes,
            name:
                'toolbox_pro_export_${DateTime.now().millisecondsSinceEpoch}.csv',
            mimeType: 'text/csv',
          );
          if (context.mounted) {
            Navigator.pop(context); // Dismiss loading
            await Share.shareXFiles([
              xFile,
            ], text: '这是从 Toolbox Pro 导出的健康与监控数据。');
          }
          return;
        }

        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/toolbox_pro_export_${DateTime.now().millisecondsSinceEpoch}.csv',
        );
        await file.writeAsString(csvString);

        if (context.mounted) {
          Navigator.pop(context); // Dismiss loading
          await Share.shareXFiles([
            XFile(file.path),
          ], text: '这是从 Toolbox Pro 导出的健康与监控数据。');
        }
      } else {
        throw Exception('Export failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('数据导出失败: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog(BuildContext context, String currentNickname) {
    final TextEditingController controller = TextEditingController(
      text: currentNickname,
    );
    bool isLoading = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF140F2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            title: const Text(
              '修改专属昵称',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: primaryColor,
                  decoration: InputDecoration(
                    hintText: '输入您的新昵称...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 1),
                    ),
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(color: primaryColor),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final newName = controller.text.trim();
                        if (newName.isEmpty || newName == currentNickname) {
                          Navigator.pop(context);
                          return;
                        }
                        setState(() => isLoading = true);
                        final success = await ref
                            .read(authProvider.notifier)
                            .updateProfile(nickname: newName);
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('昵称已同步至云端！'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('网络开小差了，修改失败。'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                child: const Text(
                  '保存至云端',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final user = ref.read(authProvider);
    if (user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ 游客模式下无法修改密码，请先注册/登录！'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;
    String? localError;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF140F2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.security_rounded,
                  color: Colors.orangeAccent,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text(
                  '安全修改密码',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '建议设置 8 位以上，包含大小写字母与特殊字符的强密码',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    controller: oldController,
                    hintText: '输入原密码',
                    icon: Icons.lock_outline_rounded,
                    isObscure: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: newController,
                    hintText: '输入新密码 (最少 6 位)',
                    icon: Icons.lock_reset_rounded,
                    isObscure: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: confirmController,
                    hintText: '再次输入新密码以确认',
                    icon: Icons.verified_user_outlined,
                    isObscure: true,
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      localError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(color: primaryColor),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final oldPass = oldController.text.trim();
                        final newPass = newController.text.trim();
                        final confirmPass = confirmController.text.trim();
                        if (oldPass.isEmpty ||
                            newPass.isEmpty ||
                            confirmPass.isEmpty) {
                          setState(() => localError = '请填写所有密码字段');
                          return;
                        }
                        if (newPass.length < 6) {
                          setState(() => localError = '新密码长度不能少于 6 位');
                          return;
                        }
                        if (newPass == oldPass) {
                          setState(() => localError = '新密码不能与原密码相同');
                          return;
                        }
                        if (newPass != confirmPass) {
                          setState(() => localError = '两次输入的新密码不一致');
                          return;
                        }
                        setState(() {
                          isLoading = true;
                          localError = null;
                        });
                        final success = await ref
                            .read(authProvider.notifier)
                            .changePassword(oldPass, newPass);
                        setState(() => isLoading = false);
                        if (success) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('密码修改成功，新密码已生效！'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } else {
                          final error =
                              ref.read(authProvider).error ?? '修改密码失败，请重试';
                          setState(() => localError = error);
                        }
                      },
                child: const Text(
                  '确认修改',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: primaryColor,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: Colors.white54, size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Color? _hexToColor(String hex) {
    try {
      String cleanHex = hex.trim().replaceAll('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  Widget _buildColorIndicatorCircle(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }

  Widget _buildCustomColorPickerSection({
    required String title,
    required Color selectedColor,
    required List<Color> presets,
    required Function(Color) onColorSelected,
  }) {
    final TextEditingController controller = TextEditingController(
      text: _colorToHex(selectedColor),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: presets.map((color) {
                    final isPresetSelected = color.value == selectedColor.value;
                    return GestureDetector(
                      onTap: () => onColorSelected(color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isPresetSelected
                                ? Colors.white
                                : Colors.white24,
                            width: isPresetSelected ? 2.5 : 1,
                          ),
                          boxShadow: isPresetSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 95,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        border: InputBorder.none,
                        hintText: '#HEX',
                        hintStyle: TextStyle(
                          color: Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                      onSubmitted: (value) {
                        final parsed = _hexToColor(value);
                        if (parsed != null) {
                          onColorSelected(parsed);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    onPressed: () {
                      final parsed = _hexToColor(controller.text);
                      if (parsed != null) {
                        onColorSelected(parsed);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showThemeSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final themeConfig = ref.watch(themeProvider);
            final currentPreset = ref.watch(themePresetProvider);
            final theme = Theme.of(context);
            final primaryColor = theme.colorScheme.primary;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: currentPreset.surface.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.palette_rounded,
                                color: Colors.pinkAccent,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '个性化主题风格定制',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: subTextColor,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        '选择内置预设主题，或开启自定义极客配色方案',
                        style: TextStyle(color: faintTextColor, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '精选内置预设主题',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 105,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: appThemePresets.length + 1,
                                itemBuilder: (context, index) {
                                  final isCustomCard =
                                      index == appThemePresets.length;
                                  final AppThemeType cardType = isCustomCard
                                      ? AppThemeType.custom
                                      : appThemePresets[index].type;
                                  final String cardName = isCustomCard
                                      ? '自定义主题'
                                      : appThemePresets[index].name;
                                  final bool isSelected =
                                      themeConfig.type == cardType;
                                  final Color pColor = isCustomCard
                                      ? themeConfig.customPrimary
                                      : appThemePresets[index].primary;
                                  final Color sColor = isCustomCard
                                      ? themeConfig.customSecondary
                                      : appThemePresets[index].secondary;
                                  final Color surfColor = isCustomCard
                                      ? themeConfig.customSurface
                                      : appThemePresets[index].surface;
                                  final bool isDark = isCustomCard
                                      ? themeConfig.customIsDark
                                      : appThemePresets[index].isDark;
                                  return GestureDetector(
                                    onTap: () {
                                      if (isCustomCard) {
                                        ref
                                            .read(themeProvider.notifier)
                                            .updateCustomTheme();
                                      } else {
                                        ref
                                            .read(themeProvider.notifier)
                                            .setThemeType(cardType);
                                      }
                                    },
                                    child: Container(
                                      width: 130,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? pColor.withOpacity(0.12)
                                            : (isDark
                                                  ? Colors.white.withOpacity(
                                                      0.02,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      0.03,
                                                    )),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? pColor
                                              : (isDark
                                                    ? Colors.white.withOpacity(
                                                        0.06,
                                                      )
                                                    : Colors.black.withOpacity(
                                                        0.08,
                                                      )),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: pColor.withOpacity(
                                                    0.1,
                                                  ),
                                                  blurRadius: 6,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  cardName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11.5,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                isDark
                                                    ? Icons.dark_mode_rounded
                                                    : Icons.light_mode_rounded,
                                                color: Colors.white54,
                                                size: 12,
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              _buildColorIndicatorCircle(
                                                pColor,
                                              ),
                                              const SizedBox(width: 4),
                                              _buildColorIndicatorCircle(
                                                sColor,
                                              ),
                                              const SizedBox(width: 4),
                                              _buildColorIndicatorCircle(
                                                surfColor,
                                              ),
                                            ],
                                          ),
                                          Text(
                                            isSelected ? '已激活' : '点击使用',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? pColor
                                                  : Colors.white30,
                                              fontSize: 9.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: themeConfig.type == AppThemeType.custom
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Divider(
                                          color: Colors.white12,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 20),
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.tune_rounded,
                                              color: Colors.cyanAccent,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '自定义配色与模式控制',
                                              style: TextStyle(
                                                color: Colors.cyanAccent,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          '主板明暗模式',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => ref
                                                    .read(
                                                      themeProvider.notifier,
                                                    )
                                                    .updateCustomTheme(
                                                      isDark: true,
                                                    ),
                                                child: Container(
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        themeConfig.customIsDark
                                                        ? themeConfig
                                                              .customPrimary
                                                              .withOpacity(0.15)
                                                        : Colors.white
                                                              .withOpacity(
                                                                0.02,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          themeConfig
                                                              .customIsDark
                                                          ? themeConfig
                                                                .customPrimary
                                                          : Colors.white
                                                                .withOpacity(
                                                                  0.08,
                                                                ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.dark_mode_rounded,
                                                        color:
                                                            themeConfig
                                                                .customIsDark
                                                            ? themeConfig
                                                                  .customPrimary
                                                            : Colors.white54,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '深色极客模式',
                                                        style: TextStyle(
                                                          color:
                                                              themeConfig
                                                                  .customIsDark
                                                              ? Colors.white
                                                              : Colors.white54,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              themeConfig
                                                                  .customIsDark
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => ref
                                                    .read(
                                                      themeProvider.notifier,
                                                    )
                                                    .updateCustomTheme(
                                                      isDark: false,
                                                    ),
                                                child: Container(
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        !themeConfig
                                                            .customIsDark
                                                        ? themeConfig
                                                              .customPrimary
                                                              .withOpacity(0.15)
                                                        : Colors.white
                                                              .withOpacity(
                                                                0.02,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          !themeConfig
                                                              .customIsDark
                                                          ? themeConfig
                                                                .customPrimary
                                                          : Colors.white
                                                                .withOpacity(
                                                                  0.08,
                                                                ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .light_mode_rounded,
                                                        color:
                                                            !themeConfig
                                                                .customIsDark
                                                            ? themeConfig
                                                                  .customPrimary
                                                            : Colors.white54,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '明亮极客模式',
                                                        style: TextStyle(
                                                          color:
                                                              !themeConfig
                                                                  .customIsDark
                                                              ? Colors.white
                                                              : Colors.white54,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              !themeConfig
                                                                  .customIsDark
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        _buildCustomColorPickerSection(
                                          title: '系统主色 (Primary Color)',
                                          selectedColor:
                                              themeConfig.customPrimary,
                                          presets: const [
                                            Color(0xFF7C4DFF),
                                            Color(0xFF2979FF),
                                            Color(0xFF00E676),
                                            Color(0xFFFF3D00),
                                            Color(0xFFFF4081),
                                            Color(0xFFFFD600),
                                            Color(0xFF00E5FF),
                                          ],
                                          onColorSelected: (color) => ref
                                              .read(themeProvider.notifier)
                                              .updateCustomTheme(
                                                primary: color,
                                              ),
                                        ),
                                        _buildCustomColorPickerSection(
                                          title: '系统辅色 (Secondary Color)',
                                          selectedColor:
                                              themeConfig.customSecondary,
                                          presets: const [
                                            Color(0xFF18FFFF),
                                            Color(0xFFFF007F),
                                            Color(0xFFFFD600),
                                            Color(0xFF1DE9B6),
                                            Color(0xFFE040FB),
                                            Color(0xFFFF3D00),
                                            Color(0xFF2979FF),
                                          ],
                                          onColorSelected: (color) => ref
                                              .read(themeProvider.notifier)
                                              .updateCustomTheme(
                                                secondary: color,
                                              ),
                                        ),
                                        _buildCustomColorPickerSection(
                                          title: '底板底色 (Surface Color)',
                                          selectedColor:
                                              themeConfig.customSurface,
                                          presets: themeConfig.customIsDark
                                              ? const [
                                                  Color(0xFF0A0714),
                                                  Color(0xFF040B14),
                                                  Color(0xFF0F0606),
                                                  Color(0xFF040A06),
                                                  Color(0xFF000000),
                                                ]
                                              : const [
                                                  Color(0xFFF5F4FA),
                                                  Color(0xFFE8F5E9),
                                                  Color(0xFFE3F2FD),
                                                  Color(0xFFFFF3E0),
                                                  Color(0xFFFFFFFF),
                                                ],
                                          onColorSelected: (color) => ref
                                              .read(themeProvider.notifier)
                                              .updateCustomTheme(
                                                surface: color,
                                              ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPersonalCenterBottomSheet(BuildContext context, String email) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xFF0C091F).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5),
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 28,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildPersonalCenterContent(context, ref, email),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileHeader(widget.userEmail, widget.userNickname),
        const SizedBox(height: 16),
        Expanded(
          child: widget.isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildProfileSettingsContent(
                        context,
                        widget.userEmail,
                        widget.userNickname,
                        widget.isWide,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: _buildPersonalCenterPanel(
                        context,
                        ref,
                        widget.userEmail,
                      ),
                    ),
                  ],
                )
              : _buildProfileSettingsContent(
                  context,
                  widget.userEmail,
                  widget.userNickname,
                  widget.isWide,
                ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildProfileHeader(String email, String nickname) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '个人主页',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E2C), Color(0xFF2D2A4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFF0F0C29),
                    child: Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showEditProfileDialog(context, nickname),
                        child: Row(
                          children: [
                            Text(
                              nickname,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.edit_rounded,
                              color: Colors.white54,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withOpacity(0.2),
                              Colors.orange.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Premium 尊享会员',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildProfileSettingsContent(
    BuildContext context,
    String email,
    String nickname,
    bool isWide,
  ) {
    final converterState = ref.watch(converterProvider);
    final customConverters = converterState.customConverters;
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _buildSettingsGroup('个性化与偏好设置', [
          _buildListTile(
            Icons.palette_outlined,
            '主题风格设置',
            Colors.pinkAccent,
            subtitle: '当前主题: ${ref.watch(themePresetProvider).name}',
            onTap: () => _showThemeSelectionBottomSheet(context),
          ),
          _buildListTile(
            Icons.straighten_rounded,
            '默认度量单位制',
            Colors.cyanAccent,
            trailing: const Text(
              '公制 (kg/cm)',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          _buildListTile(
            Icons.vibration_rounded,
            '触感反馈 (Haptics)',
            Colors.tealAccent,
            trailing: Switch(
              value: settingsState.isHapticsEnabled,
              onChanged: (v) => settingsNotifier.toggleHaptics(v),
              activeThumbColor: Colors.tealAccent,
              activeTrackColor: Colors.tealAccent.withOpacity(0.3),
            ),
          ),
          _buildListTile(
            Icons.bolt_rounded,
            '低功耗性能模式',
            Colors.amberAccent,
            subtitle: '静止背景粒子以极佳节省电量与CPU',
            trailing: Switch(
              value: settingsState.isLowPowerMode,
              onChanged: (v) => settingsNotifier.toggleLowPowerMode(v),
              activeThumbColor: Colors.amberAccent,
              activeTrackColor: Colors.amberAccent.withOpacity(0.3),
            ),
          ),
        ]),
        _buildSettingsGroup('账号与安全', [
          _buildListTile(
            Icons.devices_rounded,
            '设备与会话管理',
            Colors.blueAccent,
            subtitle: '当前在线: 1 台设备',
          ),
          _buildListTile(
            Icons.fingerprint_rounded,
            '启用面容/指纹登录',
            Colors.lightGreenAccent,
            trailing: Switch(
              value: settingsState.isBiometricsEnabled,
              onChanged: (v) => settingsNotifier.toggleBiometrics(v),
              activeThumbColor: Colors.lightGreenAccent,
              activeTrackColor: Colors.lightGreenAccent.withOpacity(0.3),
            ),
          ),
          _buildListTile(
            Icons.lock_outline_rounded,
            '修改登录密码',
            Colors.orangeAccent,
            onTap: () => _showChangePasswordDialog(context),
          ),
          _buildListTile(
            Icons.dns_rounded,
            '服务器连接设置',
            Colors.cyanAccent,
            subtitle: '自定义 API 地址与延迟测试',
            onTap: () => ServerConfigDialog.show(context),
          ),
        ]),
        _buildSettingsGroup('数据与云端', [
          _buildListTile(
            Icons.cloud_sync_rounded,
            '全双工云端同步',
            Colors.lightBlueAccent,
            subtitle: '实时同步健康数据与 AI 对话',
            trailing: Switch(
              value: true,
              onChanged: (v) {},
              activeThumbColor: Colors.lightBlueAccent,
              activeTrackColor: Colors.lightBlueAccent.withOpacity(0.3),
            ),
          ),
          _buildListTile(
            Icons.import_export_rounded,
            '导出健康与监控数据',
            Colors.greenAccent,
            subtitle: '导出为 CSV/Excel 格式',
            onTap: () => _exportData(context),
          ),
          _buildListTile(
            Icons.cleaning_services_rounded,
            '清理本地缓存',
            Colors.redAccent,
            trailing: const Text(
              '12.4 MB',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          if (!isWide)
            _buildListTile(
              Icons.analytics_outlined,
              '个人中心与数据日志',
              primaryColor,
              subtitle: '查看个人状态及数据库 Telemetry 实况',
              onTap: () => _showPersonalCenterBottomSheet(context, email),
            ),
        ]),
        _buildSettingsGroup('Sandbox 沙盒引擎', [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.rule_folder_rounded,
                  color: Colors.amberAccent,
                  size: 20,
                ),
              ),
              title: const Text(
                '自定义公式库管理',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '已加载 ${customConverters.length} 个模板',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              children: [
                if (customConverters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '暂无自定义公式，您可在“单位转换”->“沙盒公式”中自由编写！',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  )
                else
                  ...customConverters.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 0,
                        ),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '1 ${item.fromUnit} = ${item.factor} ${item.toUnit} (+${item.offset})',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          onPressed: () {
                            ref
                                .read(converterProvider.notifier)
                                .removeCustomConverter(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('公式“${item.name}”已安全销毁'),
                                backgroundColor: const Color(0xFF0F0C29),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
        _buildSettingsGroup('订阅与专属权益', [
          _buildListTile(
            Icons.card_membership_rounded,
            '我的权益包',
            Colors.amber,
            subtitle: 'Premium 尊享会员',
            trailing: const Text(
              '2099-12-31 到期',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          _buildListTile(
            Icons.api_rounded,
            'AI Token 资源用量',
            secondaryColor,
            subtitle: '本月剩余: 无限制 (Premium)',
          ),
        ]),
        _buildSettingsGroup('帮助与反馈', [
          _buildListTile(Icons.bug_report_outlined, '问题反馈与建议', Colors.white70),
          _buildListTile(
            Icons.info_outline_rounded,
            '关于 Toolbox Pro',
            Colors.white70,
            trailing: const Text(
              'v1.2.0',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          _buildListTile(
            Icons.logout_rounded,
            '安全退出登录',
            Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ]),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Toolbox Pro v1.2.0 · 工业标准级应用底座\nPowered by Advanced Flutter Architecture',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 10, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPersonalCenterPanel(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) {
    return GlassCard(
      borderColor: secondaryColor.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildPersonalCenterContent(context, ref, email),
      ),
    );
  }

  Widget _buildPersonalCenterContent(
    BuildContext context,
    WidgetRef ref,
    String email,
  ) {
    final telemetryLogs = ref.watch(telemetryLogsProvider);
    final currentApiUrl = ref.watch(apiBaseUrlProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    email.isEmpty ? "U" : email.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Premium 尊享会员',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          '🔒 云端服务器节点',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '服务地址: $currentApiUrl',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '状态',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  Text(
                    currentApiUrl.contains('47.106.119.62')
                        ? '公网节点 (深圳)'
                        : '自定义节点',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.timeline_rounded, color: primaryColor, size: 16),
                const SizedBox(width: 6),
                const Text(
                  '📊 数据库 Telemetry 实况',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white54,
                size: 16,
              ),
              onPressed: () => ref.invalidate(telemetryLogsProvider),
            ),
          ],
        ),
        const SizedBox(height: 4),
        telemetryLogs.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    '暂无 Telemetry 上报日志\n运行任何工具，数据将瞬间存盘！',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length > 5 ? 5 : logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final String toolKey = log['tool_key'] ?? '';
                final String status = log['status'] ?? 'success';
                final int duration = log['duration_ms'] ?? 0;
                final String createdAt = log['created_at'] ?? '';
                final Color color = getToolColor(toolKey, context);
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          if (index != (logs.length > 5 ? 4 : logs.length - 1))
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: Colors.white10,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getToolChineseName(toolKey),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formatTime(createdAt),
                                    style: const TextStyle(
                                      color: Colors.white30,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    status == 'success'
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.error_outline_rounded,
                                    color: status == 'success'
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status == 'success'
                                        ? '计算完成 · ${duration}ms'
                                        : '运算异常',
                                    style: TextStyle(
                                      color: status == 'success'
                                          ? Colors.greenAccent.withOpacity(0.8)
                                          : Colors.redAccent,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          error: (err, stack) => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Telemetry 数据流拉取失败',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(String groupTitle, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 12.0),
          child: Text(
            groupTitle,
            style: TextStyle(
              color: subTextColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderDividerColor),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 56.0),
                    child: Divider(color: borderDividerColor, height: 1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    Color iconColor, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: faintTextColor, fontSize: 12),
            )
          : null,
      trailing:
          trailing ??
          Icon(Icons.chevron_right_rounded, color: faintTextColor, size: 20),
      onTap: onTap ?? () {},
    );
  }
}
