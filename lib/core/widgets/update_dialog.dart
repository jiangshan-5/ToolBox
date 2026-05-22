import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'glass_card.dart';
import 'dynamic_effects.dart';

class UpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String changelog;
  final String downloadUrl;
  final bool forceUpdate;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.changelog,
    required this.downloadUrl,
    required this.forceUpdate,
  });

  /// Static helper to trigger the dialog beautifully
  static void show(
    BuildContext context, {
    required String latestVersion,
    required String changelog,
    required String downloadUrl,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => UpdateDialog(
        latestVersion: latestVersion,
        changelog: changelog,
        downloadUrl: downloadUrl,
        forceUpdate: forceUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Intercept back button gestures on Android/iOS if this is a force update
    return PopScope(
      canPop: !forceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          child: GlassCard(
            glowColor: Colors.deepPurpleAccent,
            child: Stack(
              children: [
                // Cyberpunk decorative background glow circles inside card
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.15),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Rocket/Sync Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepPurpleAccent.withOpacity(0.12),
                            border: Border.all(
                              color: Colors.deepPurpleAccent.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurpleAccent.withOpacity(0.3),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.system_update_alt_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      const Center(
                        child: Text(
                          '发现新版本',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Version Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.purpleAccent.shade400.withOpacity(0.4),
                            ),
                            color: Colors.purpleAccent.shade400.withOpacity(0.1),
                          ),
                          child: Text(
                            'v$latestVersion',
                            style: TextStyle(
                              color: Colors.purpleAccent.shade100,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Changelog Section Title
                      const Text(
                        '更新日志：',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Scrollable Changelog
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  changelog.replaceAll('\\n', '\n'),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13.5,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Buttons
                      Row(
                        children: [
                          if (!forceUpdate) ...[
                            Expanded(
                              child: ScaleOnTap(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    color: Colors.white.withOpacity(0.04),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '暂不更新',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: ScaleOnTap(
                              onTap: () => _copyLinkAndNotify(context),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
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
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '复制下载链接',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Helpful fallback instructions
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          forceUpdate ? '此版本为强制更新，复制链接后在浏览器中打开即可下载安装。' : '复制下载链接后，可在浏览器中粘贴打开下载。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Absolute Close Button (Only for optional updates)
                if (!forceUpdate)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white.withOpacity(0.5)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyLinkAndNotify(BuildContext context) {
    Clipboard.setData(ClipboardData(text: downloadUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('下载链接已复制到剪贴板，请在浏览器中打开下载！'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
    if (!forceUpdate) {
      Navigator.pop(context);
    }
  }
}
