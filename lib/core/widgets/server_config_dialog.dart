import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/api_config_provider.dart';
import '../network/api_client.dart';

class ServerConfigDialog extends ConsumerStatefulWidget {
  const ServerConfigDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  ConsumerState<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends ConsumerState<ServerConfigDialog> {
  late TextEditingController _controller;
  String? _pingResult;
  Color _pingColor = Colors.white70;
  bool _isTesting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(apiBaseUrlProvider);
    _controller = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      backgroundColor: const Color(0xFF140F2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      title: Row(
        children: [
          const Icon(Icons.dns_rounded, color: Colors.cyanAccent, size: 24),
          const SizedBox(width: 10),
          const Text(
            '服务器连接设置',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '真机调试或私有化部署时，您可输入自定义后端 API 地址 (如 http://192.168.1.100:8000)',
              style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: primaryColor,
              decoration: InputDecoration(
                hintText: '服务器基准地址',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                prefixIcon: const Icon(Icons.link_rounded, color: Colors.white54, size: 18),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: _isTesting 
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.cyanAccent),
                        )
                      : const Icon(Icons.speed_rounded, size: 16, color: Colors.cyanAccent),
                  label: const Text('测试延迟 (Ping)', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  onPressed: _isTesting || _isSaving
                      ? null
                      : () async {
                          final inputUrl = _controller.text.trim();
                          if (inputUrl.isEmpty) {
                            setState(() {
                              _pingResult = '请输入有效的 URL';
                              _pingColor = Colors.redAccent;
                            });
                            return;
                          }
                          
                          setState(() {
                            _isTesting = true;
                            _pingResult = '正在测试连接...';
                            _pingColor = Colors.cyanAccent;
                          });

                          // Perform local connection test
                          String testUrl = inputUrl;
                          if (!testUrl.startsWith('http://') && !testUrl.startsWith('https://')) {
                            testUrl = 'http://$testUrl';
                          }
                          if (!testUrl.contains('/api/v1')) {
                            if (testUrl.endsWith('/')) {
                              testUrl = testUrl.substring(0, testUrl.length - 1);
                            }
                            testUrl = '$testUrl/api/v1';
                          }

                          final stopwatch = Stopwatch()..start();
                          try {
                            final dio = Dio(BaseOptions(
                              connectTimeout: const Duration(seconds: 4),
                              receiveTimeout: const Duration(seconds: 4),
                            ));
                            await dio.get('$testUrl/system/version');
                            stopwatch.stop();
                            final ms = stopwatch.elapsedMilliseconds;
                            setState(() {
                              _isTesting = false;
                              _pingResult = '连接成功！延迟: ${ms}ms';
                              _pingColor = Colors.greenAccent;
                            });
                          } catch (e) {
                            stopwatch.stop();
                            setState(() {
                              _isTesting = false;
                              _pingResult = '连接失败，请检查服务是否开启或 IP 是否正确';
                              _pingColor = Colors.redAccent;
                            });
                          }
                        },
                ),
                TextButton(
                  child: const Text('恢复默认', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onPressed: _isTesting || _isSaving
                      ? null
                      : () {
                          _controller.text = ApiClient.defaultBaseUrl;
                        },
                ),
              ],
            ),
            if (_pingResult != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _pingColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _pingColor.withOpacity(0.2)),
                ),
                child: Text(
                  _pingResult!,
                  style: TextStyle(color: _pingColor, fontSize: 12),
                ),
              ),
            ],
            if (_isSaving) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(color: primaryColor),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving || _isTesting ? null : () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSaving || _isTesting
              ? null
              : () async {
                  final newUrl = _controller.text.trim();
                  setState(() => _isSaving = true);
                  
                  await ref.read(apiBaseUrlProvider.notifier).updateBaseUrl(newUrl);
                  
                  setState(() => _isSaving = false);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('服务器地址已更新并重启连接！\n当前：${ref.read(apiBaseUrlProvider)}'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
          child: const Text('保存修改', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
