import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../settings/provider/settings_provider.dart';
import '../../../converter/provider/converter_provider.dart';
import '../../../debug/view/debug_console_screen.dart';
import 'profile/profile_dialogs.dart';
import 'profile/profile_header.dart';
import 'profile/personal_center_panel.dart';
import 'profile/profile_theme_dialogs.dart';

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
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;
  Color get faintTextColor => isDark ? Colors.white38 : Colors.black38;
  Color get borderDividerColor =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileHeader(
          userEmail: widget.userEmail,
          userNickname: widget.userNickname,
        ),
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
                      child: PersonalCenterPanel(
                        email: widget.userEmail,
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
            onTap: () => ProfileThemeDialogs.showThemeSelectionBottomSheet(context, ref),
          ),
          _buildListTile(
            Icons.straighten_rounded,
            '默认度量单位制',
            Colors.cyanAccent,
            trailing: Text(
              '公制 (kg/cm)',
              style: TextStyle(color: faintTextColor, fontSize: 12),
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
          if (email == 'admin@toolbox.com')
            _buildListTile(
              Icons.terminal_rounded,
              '系统级高级控制台',
              Colors.purpleAccent,
              subtitle: '发布更新公告及管理云端系统实况',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebugConsoleScreen()),
                );
              },
            ),
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
            onTap: () => ProfileDialogs.showChangePasswordDialog(context, ref),
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
            onTap: () => ProfileDialogs.exportData(context, ref),
          ),
          _buildListTile(
            Icons.cleaning_services_rounded,
            '清理本地缓存',
            Colors.redAccent,
            trailing: Text(
              '12.4 MB',
              style: TextStyle(color: faintTextColor, fontSize: 12),
            ),
          ),
          if (!isWide)
            _buildListTile(
              Icons.analytics_outlined,
              '个人中心与数据日志',
              primaryColor,
              subtitle: '查看个人状态及数据库 Telemetry 实况',
              onTap: () => ProfileDialogs.showPersonalCenterBottomSheet(context, ref, email),
            ),
        ]),
        _buildSettingsGroup('Sandbox 沙盒引擎', [
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              iconTheme: IconThemeData(color: faintTextColor),
              unselectedWidgetColor: faintTextColor,
            ),
            child: ExpansionTile(
              iconColor: subTextColor,
              collapsedIconColor: faintTextColor,
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
              title: Text(
                '自定义公式库管理',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '已加载 ${customConverters.length} 个模板',
                style: TextStyle(color: faintTextColor, fontSize: 12),
              ),
              children: [
                if (customConverters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '暂无自定义公式，您可在“单位转换”->“沙盒公式”中自由编写！',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: faintTextColor, fontSize: 12),
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
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '1 ${item.fromUnit} = ${item.factor} ${item.toUnit} (+${item.offset})',
                          style: TextStyle(
                            color: faintTextColor,
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
            trailing: Text(
              '2099-12-31 到期',
              style: TextStyle(color: faintTextColor, fontSize: 12),
            ),
          ),
          _buildListTile(
            Icons.api_rounded,
            'AI Token 资源用量',
            Theme.of(context).colorScheme.secondary,
            subtitle: '本月剩余: 无限制 (Premium)',
          ),
        ]),
        _buildSettingsGroup('帮助与反馈', [
          _buildListTile(
            Icons.bug_report_outlined,
            '问题反馈与建议',
            isDark ? Colors.white70 : Colors.black54,
            onTap: () => ProfileDialogs.showFeedbackDialog(context, ref),
          ),
          _buildListTile(
            Icons.info_outline_rounded,
            '关于 Toolbox Pro',
            isDark ? Colors.white70 : Colors.black54,
            trailing: Text(
              'v1.2.0',
              style: TextStyle(color: faintTextColor, fontSize: 12),
            ),
            onTap: () => ProfileDialogs.showAboutDialog(context, ref),
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
        Center(
          child: Text(
            'Toolbox Pro v1.2.0 · 工业标准级应用底座\nPowered by Advanced Flutter Architecture',
            textAlign: TextAlign.center,
            style: TextStyle(color: faintTextColor, fontSize: 10, height: 1.5),
          ),
        ),
        const SizedBox(height: 32),
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
