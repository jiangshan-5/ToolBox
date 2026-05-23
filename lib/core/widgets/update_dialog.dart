import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'glass_card.dart';
import 'dynamic_effects.dart';

class UpdateDialog extends StatefulWidget {
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
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = '';
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel("Dialog dismissed");
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = '准备下载...';
    });

    try {
      final storageDir = await getTemporaryDirectory();
      final savePath = '${storageDir.path}/toolbox_update.apk';

      // Clean up pre-existing download file
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      _cancelToken = CancelToken();

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              final percent = (_progress * 100).toStringAsFixed(1);
              _statusText = '正在下载: $percent%';
            });
          } else {
            setState(() {
              _statusText =
                  '已下载: ${(received / 1024 / 1024).toStringAsFixed(1)} MB';
            });
          }
        },
      );

      setState(() {
        _progress = 1.0;
        _statusText = '下载完成，正在唤醒安装...';
      });

      // Prompt OS package installer with explicit APK MIME type
      final result = await OpenFile.open(
        savePath,
        type: "application/vnd.android.package-archive",
      );

      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('启动系统安装失败: ${result.message}。请长按下方复制链接手动下载。'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isDownloading = false;
          });
        }
      } else {
        if (mounted && !widget.forceUpdate) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _progress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载更新失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyLinkAndNotify() {
    Clipboard.setData(ClipboardData(text: widget.downloadUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('下载链接已复制到剪贴板，您可在手机浏览器中手动粘贴下载！'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Intercept back button gestures on Android/iOS if this is a force update or downloading
    final canPop = !widget.forceUpdate && !_isDownloading;

    return Theme(
      data: ThemeData.dark(),
      child: PopScope(
        canPop: canPop,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 40.0,
          ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
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
                                  color: Colors.deepPurpleAccent.withOpacity(
                                    0.3,
                                  ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.purpleAccent.shade400.withOpacity(
                                  0.4,
                                ),
                              ),
                              color: Colors.purpleAccent.shade400.withOpacity(
                                0.1,
                              ),
                            ),
                            child: Text(
                              'v${widget.latestVersion}',
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
                                    widget.changelog.replaceAll('\\n', '\n'),
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

                        // Action Layout (Downloading Progress vs Buttons)
                        if (_isDownloading) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _statusText,
                                    style: TextStyle(
                                      color: Colors.purpleAccent.shade100,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${(_progress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  height: 8,
                                  child: LinearProgressIndicator(
                                    value: _progress,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.08,
                                    ),
                                    color: Colors.deepPurpleAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  widget.forceUpdate
                                      ? '正在极速下载安装包，请勿关闭应用'
                                      : '正在后台下载，您可以稍等片刻...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Action Buttons
                          Row(
                            children: [
                              if (!widget.forceUpdate) ...[
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
                                  onTap: _startDownload,
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
                                          color: Colors.deepPurpleAccent
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      '立即极速更新',
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

                          // Copy URL option in small text
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _copyLinkAndNotify,
                            child: Center(
                              child: Text(
                                '手动复制下载链接',
                                style: TextStyle(
                                  color: Colors.purpleAccent.shade100
                                      .withOpacity(0.7),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Absolute Close Button (Only for optional updates, and not currently downloading)
                  if (!widget.forceUpdate && !_isDownloading)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
