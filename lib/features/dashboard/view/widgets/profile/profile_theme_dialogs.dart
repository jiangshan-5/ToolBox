import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/app_theme.dart';

class ProfileThemeDialogs {
  ProfileThemeDialogs._();

  static Color _primaryColor(BuildContext context) => Theme.of(context).colorScheme.primary;
  static bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color _textColor(BuildContext context) => _isDark(context) ? Colors.white : Colors.black87;
  static Color _subTextColor(BuildContext context) => _isDark(context) ? Colors.white70 : Colors.black54;
  static Color _faintTextColor(BuildContext context) => _isDark(context) ? Colors.white38 : Colors.black38;
  static Color _borderDividerColor(BuildContext context) =>
      _isDark(context) ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  static Color? _hexToColor(String hex) {
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

  static Widget _buildColorIndicatorCircle(Color color) {
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

  static Widget _buildCustomColorPickerSection({
    required BuildContext context,
    required String title,
    required Color selectedColor,
    required List<Color> presets,
    required Function(Color) onColorSelected,
  }) {
    final subTextColorVal = _subTextColor(context);
    final borderDividerColorVal = _borderDividerColor(context);
    final isDarkVal = _isDark(context);
    final textColorVal = _textColor(context);
    final faintTextColorVal = _faintTextColor(context);

    final TextEditingController controller = TextEditingController(
      text: _colorToHex(selectedColor),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: subTextColorVal,
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
                                ? (isDarkVal ? Colors.white : Colors.black87)
                                : (isDarkVal ? Colors.white24 : Colors.black12),
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
                color: isDarkVal
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderDividerColorVal),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(color: textColorVal, fontSize: 11),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        border: InputBorder.none,
                        hintText: '#HEX',
                        hintStyle: TextStyle(
                          color: faintTextColorVal,
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

  static void showThemeSelectionBottomSheet(BuildContext context, WidgetRef ref) {
    final borderDividerColorVal = _borderDividerColor(context);
    final isDarkVal = _isDark(context);
    final textColorVal = _textColor(context);
    final subTextColorVal = _subTextColor(context);
    final faintTextColorVal = _faintTextColor(context);

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
            final pColor = theme.colorScheme.primary;
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
                      color: pColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: [
                     BoxShadow(
                      color: pColor.withOpacity(0.1),
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
                                  color: textColorVal,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: subTextColorVal,
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
                        style: TextStyle(color: faintTextColorVal, fontSize: 12),
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
                                color: subTextColorVal,
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
                                  final Color prePColor = isCustomCard
                                      ? themeConfig.customPrimary
                                      : appThemePresets[index].primary;
                                  final Color preSColor = isCustomCard
                                      ? themeConfig.customSecondary
                                      : appThemePresets[index].secondary;
                                  final Color surfColor = isCustomCard
                                      ? themeConfig.customSurface
                                      : appThemePresets[index].surface;
                                  final bool preIsDark = isCustomCard
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
                                            ? prePColor.withOpacity(0.12)
                                            : (preIsDark
                                                  ? Colors.white.withOpacity(
                                                      0.02,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      0.03,
                                                    )),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? prePColor
                                              : (preIsDark
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
                                                  color: prePColor.withOpacity(
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
                                                    color: textColorVal,
                                                    fontSize: 11.5,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                preIsDark
                                                    ? Icons.dark_mode_rounded
                                                    : Icons.light_mode_rounded,
                                                color: subTextColorVal,
                                                size: 12,
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              _buildColorIndicatorCircle(
                                                prePColor,
                                              ),
                                              const SizedBox(width: 4),
                                              _buildColorIndicatorCircle(
                                                preSColor,
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
                                                  ? prePColor
                                                  : faintTextColorVal,
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
                                        Divider(
                                          color: borderDividerColorVal,
                                          height: 1,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.tune_rounded,
                                              color: pColor,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '自定义配色与模式控制',
                                              style: TextStyle(
                                                color: pColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '主板明暗模式',
                                          style: TextStyle(
                                            color: subTextColorVal,
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
                                                        : (isDarkVal
                                                            ? Colors.white.withOpacity(0.02)
                                                            : Colors.black.withOpacity(0.03)),
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
                                                          : borderDividerColorVal,
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
                                                            : subTextColorVal,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '深色极客模式',
                                                        style: TextStyle(
                                                          color:
                                                              themeConfig
                                                                  .customIsDark
                                                              ? textColorVal
                                                              : subTextColorVal,
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
                                                        : (isDarkVal
                                                            ? Colors.white.withOpacity(0.02)
                                                            : Colors.black.withOpacity(0.03)),
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
                                                          : borderDividerColorVal,
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
                                                            : subTextColorVal,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '明亮极客模式',
                                                        style: TextStyle(
                                                          color:
                                                              !themeConfig
                                                                  .customIsDark
                                                              ? textColorVal
                                                              : subTextColorVal,
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
                                          context: context,
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
                                          context: context,
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
                                          context: context,
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
                                        const SizedBox(height: 20),
                                        Text(
                                          '上传应用背景图片 (Custom Background)',
                                          style: TextStyle(
                                            color: subTextColorVal,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (themeConfig.customBgBase64 != null) ...[
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDarkVal
                                                  ? Colors.white.withOpacity(0.04)
                                                  : Colors.black.withOpacity(0.04),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: borderDividerColorVal,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.memory(
                                                    base64Decode(
                                                      themeConfig.customBgBase64!.contains(',')
                                                          ? themeConfig.customBgBase64!.split(',')[1]
                                                          : themeConfig.customBgBase64!,
                                                    ),
                                                    width: 50,
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    '自定义背景图已加载\n(流光模糊滤镜已自动启用)',
                                                    style: TextStyle(
                                                      color: subTextColorVal,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_forever_rounded,
                                                    color: Colors.redAccent,
                                                  ),
                                                  onPressed: () {
                                                    ref.read(themeProvider.notifier).updateCustomTheme(clearBg: true);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('背景图片已成功卸载'),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ] else ...[
                                          GestureDetector(
                                            onTap: () async {
                                              try {
                                                final result = await FilePicker.platform.pickFiles(
                                                  type: FileType.image,
                                                  withData: true,
                                                );
                                                if (result != null && result.files.isNotEmpty) {
                                                  final file = result.files.first;
                                                  final bytes = file.bytes;
                                                  if (bytes != null) {
                                                    if (bytes.length > 2 * 1024 * 1024) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('图片体积过大，请上传小于2MB的图片'),
                                                            backgroundColor: Colors.orangeAccent,
                                                            behavior: SnackBarBehavior.floating,
                                                          ),
                                                        );
                                                      }
                                                      return;
                                                    }
                                                    final base64Str = base64Encode(bytes);
                                                    ref.read(themeProvider.notifier).updateCustomTheme(
                                                      bgBase64: 'data:image/png;base64,$base64Str',
                                                    );
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('自定义背景已就绪！已启用毛玻璃微光融合效果'),
                                                          backgroundColor: Colors.green,
                                                          behavior: SnackBarBehavior.floating,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('背景读取失败: $e'),
                                                      backgroundColor: Colors.redAccent,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: Container(
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: isDarkVal
                                                    ? Colors.white.withOpacity(0.04)
                                                    : Colors.black.withOpacity(0.04),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: borderDividerColorVal,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.upload_file_rounded,
                                                    color: subTextColorVal,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '上传专属背景图片 (.png/.jpg)',
                                                    style: TextStyle(
                                                      color: subTextColorVal,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
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
}
