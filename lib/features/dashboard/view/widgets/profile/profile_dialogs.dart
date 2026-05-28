import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/app_theme.dart';
import '../../../../../core/providers/api_config_provider.dart';
import '../../../../../core/providers/package_info_provider.dart';
import '../../../../../core/widgets/glass_card.dart';
import '../../../../../core/widgets/update_dialog.dart';
import '../../../../auth/provider/auth_provider.dart';
import '../dashboard_utils.dart';
import 'personal_center_panel.dart';

class ProfileDialogs {
  ProfileDialogs._();

  static const List<Map<String, String>> cyberAvatars = [
    {'name': 'Matrix Hacker ⚡', 'value': '⚡'},
    {'name': 'Neon Cyborg 🤖', 'value': '🤖'},
    {'name': 'Cyber Sakura 🌸', 'value': '🌸'},
    {'name': 'Pixel Runner 🏃', 'value': '🏃'},
    {'name': 'Aero Pilot 🚀', 'value': '🚀'},
    {'name': 'Cosmic Sage 🔮', 'value': '🔮'},
  ];

  static Color _primaryColor(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color _secondaryColor(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color _textColor(BuildContext context) => _isDark(context) ? Colors.white : Colors.black87;
  static Color _subTextColor(BuildContext context) => _isDark(context) ? Colors.white70 : Colors.black54;
  static Color _faintTextColor(BuildContext context) => _isDark(context) ? Colors.white38 : Colors.black38;
  static Color _borderDividerColor(BuildContext context) =>
      _isDark(context) ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  static Widget buildAvatarWidget(String? avatarUrl, double radius) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF0F0C29),
        child: Icon(
          Icons.person_rounded,
          size: radius * 1.1,
          color: Colors.white,
        ),
      );
    }

    if (avatarUrl.startsWith('data:image/') || avatarUrl.length > 50) {
      try {
        final cleanBase64 = avatarUrl.contains(',') ? avatarUrl.split(',')[1] : avatarUrl;
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.transparent,
          backgroundImage: MemoryImage(base64Decode(cleanBase64)),
        );
      } catch (_) {}
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF100E26),
      child: Text(
        avatarUrl,
        style: TextStyle(fontSize: radius * 1.1),
      ),
    );
  }

  static Future<void> exportData(BuildContext context, WidgetRef ref) async {
    final pColor = _primaryColor(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: pColor)),
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

  static void showFeedbackDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = 'bug';
    bool isLoading = false;
    String? localError;

    final isDarkVal = _isDark(context);
    final textColorVal = _textColor(context);
    final pColor = _primaryColor(context);
    final subTextColorVal = _subTextColor(context);
    final faintTextColorVal = _faintTextColor(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDarkVal ? const Color(0xFF140F2D) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: pColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.bug_report_rounded,
                  color: pColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '问题反馈与建议',
                  style: TextStyle(
                    color: textColorVal,
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
                  Text(
                    '您的反馈是产品改进的最大动力！我们会认真阅读每一条建议。',
                    style: TextStyle(color: faintTextColorVal, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: isDarkVal ? const Color(0xFF140F2D) : Colors.white,
                    style: TextStyle(color: textColorVal, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: '反馈类别',
                      labelStyle: TextStyle(color: subTextColorVal, fontSize: 12),
                      filled: true,
                      fillColor: isDarkVal ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'bug', child: Text('程序故障 (Bug)')),
                      DropdownMenuItem(value: 'feature_request', child: Text('新功能建议 (Feature)')),
                      DropdownMenuItem(value: 'billing', child: Text('账户与订阅 (Billing)')),
                      DropdownMenuItem(value: 'other', child: Text('其他建议 (Other)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => category = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    context: context,
                    controller: titleController,
                    hintText: '简明扼要的标题',
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    style: TextStyle(color: textColorVal, fontSize: 14),
                    cursorColor: pColor,
                    decoration: InputDecoration(
                      hintText: '详细描述您遇到的问题或您的建议...',
                      hintStyle: TextStyle(
                        color: isDarkVal ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: isDarkVal ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: pColor, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
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
                    LinearProgressIndicator(color: pColor),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  '取消',
                  style: TextStyle(color: faintTextColorVal),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        final desc = descController.text.trim();
                        if (title.isEmpty || desc.isEmpty) {
                          setState(() => localError = '请填写标题与描述');
                          return;
                        }
                        setState(() {
                          isLoading = true;
                          localError = null;
                        });
                        try {
                          final apiClient = ref.read(apiClientProvider);
                          final response = await apiClient.instance.post(
                            '/system/feedback',
                            data: {
                              'category': category,
                              'title': title,
                              'description': desc,
                            },
                          );
                          setState(() => isLoading = false);
                          if (response.statusCode == 200 && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(response.data['detail'] ?? '反馈已成功提交！'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            throw Exception('提交失败');
                          }
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                            localError = '网络连接失败，请稍后重试。';
                          });
                        }
                      },
                child: const Text(
                  '提交反馈',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showAboutDialog(BuildContext context, WidgetRef ref) {
    bool isChecking = false;
    final isDarkVal = _isDark(context);
    final textColorVal = _textColor(context);
    final pColor = _primaryColor(context);
    final sColorVal = _secondaryColor(context);
    final subTextColorVal = _subTextColor(context);
    final faintTextColorVal = _faintTextColor(context);
    final borderDividerColorVal = _borderDividerColor(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDarkVal ? const Color(0xFF140F2D) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: pColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: pColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '关于 Toolbox Pro',
                  style: TextStyle(
                    color: textColorVal,
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
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [pColor, sColorVal],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: pColor.withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.home_repair_service_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Toolbox Pro',
                          style: TextStyle(
                            color: textColorVal,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final packageInfo = ref.read(packageInfoProvider);
                            return Text(
                              'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})',
                              style: TextStyle(
                                color: faintTextColorVal,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '工业标准级通用实用工具箱底座，搭载尖端 Flutter 架构体系，集本地离线计算、多时区番茄钟、健康BMI监测与高级 AI 智能助手于一体。内置本地离线隔离保护罩，确保您的敏感运算与隐私数据绝不外流。',
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: subTextColorVal,
                      fontSize: 12.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderDividerColorVal, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '技术开发团队',
                        style: TextStyle(color: faintTextColorVal, fontSize: 11.5),
                      ),
                      Text(
                        'Advanced Agentic Team',
                        style: TextStyle(color: subTextColorVal, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '服务运行状态',
                        style: TextStyle(color: faintTextColorVal, fontSize: 11.5),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '正常连接',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isChecking) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(color: pColor),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '关闭',
                  style: TextStyle(color: faintTextColorVal),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isChecking
                    ? null
                    : () async {
                        setState(() => isChecking = true);
                        try {
                          final apiClient = ref.read(apiClientProvider);
                          final response = await apiClient.instance.get('/system/version');
                          final data = response.data;
                          setState(() => isChecking = false);
                          if (data != null && context.mounted) {
                            final latestVersion = data['latest_version'] as String;
                            final versionCode = data['version_code'] as int;
                            final changelog = data['changelog'] as String;
                            final downloadUrl = data['download_url'] as String;
                            final forceUpdate = data['force_update'] as bool;
                            final packageInfo = ref.read(packageInfoProvider);
                            final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
                            
                            if (versionCode > currentVersionCode) {
                              Navigator.pop(context);
                              UpdateDialog.show(
                                context,
                                latestVersion: latestVersion,
                                changelog: changelog,
                                downloadUrl: downloadUrl,
                                forceUpdate: forceUpdate,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✨ 当前已是最新版本，无需更新！'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setState(() => isChecking = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('检查更新失败: ${e.toString()}'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                child: const Text(
                  '检查新版本',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showEditProfileDialog(BuildContext context, WidgetRef ref, String currentNickname) {
    final TextEditingController controller = TextEditingController(
      text: currentNickname,
    );
    bool isLoading = false;
    final isDarkVal = _isDark(context);
    final textColorVal = _textColor(context);
    final pColor = _primaryColor(context);
    final faintTextColorVal = _faintTextColor(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDarkVal ? const Color(0xFF140F2D) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: pColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            title: Text(
              '修改专属昵称',
              style: TextStyle(
                color: textColorVal,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  style: TextStyle(color: textColorVal),
                  cursorColor: pColor,
                  decoration: InputDecoration(
                    hintText: '输入您的新昵称...',
                    hintStyle: TextStyle(
                      color: isDarkVal ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: isDarkVal ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: pColor, width: 1),
                    ),
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(color: pColor),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  '取消',
                  style: TextStyle(color: faintTextColorVal),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pColor.withOpacity(0.8),
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

  static void showChangePasswordDialog(BuildContext context, WidgetRef ref) {
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

    final isDarkVal = _isDark(context);
    final textColorVal = _textColor(context);
    final pColor = _primaryColor(context);
    final faintTextColorVal = _faintTextColor(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDarkVal ? const Color(0xFF140F2D) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: pColor.withOpacity(0.3),
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
                Text(
                  '安全修改密码',
                  style: TextStyle(
                    color: textColorVal,
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
                  Text(
                    '建议设置 8 位以上，包含大小写字母与特殊字符的强密码',
                    style: TextStyle(color: faintTextColorVal, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  _buildDialogTextField(
                    context: context,
                    controller: oldController,
                    hintText: '输入原密码',
                    icon: Icons.lock_outline_rounded,
                    isObscure: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    context: context,
                    controller: newController,
                    hintText: '输入新密码 (最少 6 位)',
                    icon: Icons.lock_reset_rounded,
                    isObscure: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    context: context,
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
                    LinearProgressIndicator(color: pColor),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  '取消',
                  style: TextStyle(color: faintTextColorVal),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pColor,
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



  static void showPersonalCenterBottomSheet(BuildContext context, WidgetRef ref, String email) {
    final isDarkVal = _isDark(context);
    final pColor = _primaryColor(context);
    final borderDividerColorVal = _borderDividerColor(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDarkVal ? const Color(0xFF0C091F).withOpacity(0.95) : Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: isDarkVal ? pColor.withOpacity(0.3) : borderDividerColorVal,
                width: 1.5,
              ),
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
                    color: isDarkVal ? Colors.white24 : Colors.black12,
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
                  child: PersonalCenterContent(email: email),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showAvatarSelectionDialog(BuildContext context, WidgetRef ref) {
    final pColor = _primaryColor(context);
    final textColorVal = _textColor(context);
    final subTextColorVal = _subTextColor(context);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            borderColor: pColor.withOpacity(0.3),
            glowColor: pColor,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.face_retouching_natural_rounded, color: Colors.pinkAccent),
                      const SizedBox(width: 8),
                      Text(
                        '自定义赛博头像',
                        style: TextStyle(color: textColorVal, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: cyberAvatars.length,
                      itemBuilder: (context, index) {
                        final avatar = cyberAvatars[index];
                        return GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await ref.read(authProvider.notifier).updateProfile(avatarUrl: avatar['value']);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✨ 赛博头像设置成功！已同步至云端'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: pColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: pColor.withOpacity(0.2)),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(avatar['value']!, style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 4),
                                Text(avatar['name']!.split(' ').first, style: TextStyle(color: subTextColorVal, fontSize: 9)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            final bytes = file.bytes;
                            if (bytes != null) {
                              if (bytes.length > 1 * 1024 * 1024) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('头像大小超出 1MB 限制'),
                                          backgroundColor: Colors.orangeAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                    return;
                                  }
                              final base64Str = base64Encode(bytes);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                              await ref.read(authProvider.notifier).updateProfile(
                                avatarUrl: 'data:image/png;base64,$base64Str',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✨ 自定义头像上传成功！已同步至云端'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          debugPrint('Error uploading custom avatar: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.cloud_upload_rounded, color: Colors.black),
                      label: const Text('上传本地图片作为头像', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showEditBioDialog(BuildContext context, WidgetRef ref, String currentBio) {
    final TextEditingController bioController = TextEditingController(text: currentBio);
    bool isLoading = false;
    final isDarkVal = _isDark(context);
    final textColorVal = _textColor(context);
    final pColor = _primaryColor(context);
    final faintTextColorVal = _faintTextColor(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDarkVal ? const Color(0xFF140F2D) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: pColor.withOpacity(0.3), width: 1.5),
            ),
            title: Text(
              '修改专属个性签名',
              style: TextStyle(color: textColorVal, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  maxLength: 50,
                  style: TextStyle(color: textColorVal, fontSize: 13.5),
                  cursorColor: pColor,
                  decoration: InputDecoration(
                    hintText: '写下您的签名，彰显极客身份...',
                    hintStyle: TextStyle(
                      color: isDarkVal ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: isDarkVal ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: pColor, width: 1),
                    ),
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(color: pColor),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text('取消', style: TextStyle(color: faintTextColorVal)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: pColor.withOpacity(0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final newBio = bioController.text.trim();
                        setState(() => isLoading = true);
                        final success = await ref
                            .read(authProvider.notifier)
                            .updateProfile(bio: newBio);
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✨ 个性签名已同步至云端！'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('网络故障，修改失败。'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('保存至云端', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildDialogTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isObscure = false,
  }) {
    final pColor = _primaryColor(context);
    final textColorVal = _textColor(context);
    final isDarkVal = _isDark(context);

    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: TextStyle(color: textColorVal, fontSize: 14),
      cursorColor: pColor,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDarkVal ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: isDarkVal ? Colors.white54 : Colors.black54, size: 18),
        filled: true,
        fillColor: isDarkVal ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: pColor, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }


}
