import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../features/dashboard/provider/tools_provider.dart';

class DevEncoderScreen extends ConsumerStatefulWidget {
  const DevEncoderScreen({super.key});

  @override
  ConsumerState<DevEncoderScreen> createState() => _DevEncoderScreenState();
}

class _DevEncoderScreenState extends ConsumerState<DevEncoderScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  String _activeOperation = 'base64_encode'; // default
  String? _errorMessage;
  int _jsonSpacing = 2; // For JSON Formatting spacing
  
  // Analytics Logging Debounce
  DateTime? _lastLoggedTime;
  String? _lastLoggedOp;

  final List<Map<String, dynamic>> _operations = [
    {'key': 'base64_encode', 'label': 'Base64 编码', 'icon': Icons.enhanced_encryption_rounded, 'color': Colors.cyanAccent},
    {'key': 'base64_decode', 'label': 'Base64 解码', 'icon': Icons.no_encryption_gmailerrorred_rounded, 'color': Colors.cyanAccent},
    {'key': 'url_encode', 'label': 'URL 编码', 'icon': Icons.link_rounded, 'color': Colors.greenAccent},
    {'key': 'url_decode', 'label': 'URL 解码', 'icon': Icons.link_off_rounded, 'color': Colors.greenAccent},
    {'key': 'md5', 'label': 'MD5 哈希', 'icon': Icons.fingerprint_rounded, 'color': Colors.orangeAccent},
    {'key': 'sha256', 'label': 'SHA-256 哈希', 'icon': Icons.security_rounded, 'color': Colors.pinkAccent},
    {'key': 'json_format', 'label': 'JSON 格式化', 'icon': Icons.format_align_left_rounded, 'color': Colors.purpleAccent},
    {'key': 'json_minify', 'label': 'JSON 压缩', 'icon': Icons.compress_rounded, 'color': Colors.amberAccent},
  ];

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_processInput);
    
    // Initial seed input just to make it interesting
    _inputController.text = '{"name": "Cyber Toolbox", "version": "1.0", "status": "online"}';
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _processInput() {
    final input = _inputController.text;
    if (input.isEmpty) {
      setState(() {
        _outputController.clear();
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      String result = '';
      switch (_activeOperation) {
        case 'base64_encode':
          result = base64.encode(utf8.encode(input));
          break;
        case 'base64_decode':
          // Strip white space if any to prevent false parsing errors
          final cleaned = input.replaceAll(RegExp(r'\s+'), '');
          result = utf8.decode(base64.decode(cleaned));
          break;
        case 'url_encode':
          result = Uri.encodeComponent(input);
          break;
        case 'url_decode':
          result = Uri.decodeComponent(input);
          break;
        case 'md5':
          final bytes = utf8.encode(input);
          result = md5.convert(bytes).toString();
          break;
        case 'sha256':
          final bytes = utf8.encode(input);
          result = sha256.convert(bytes).toString();
          break;
        case 'json_format':
          final parsed = json.decode(input);
          final encoder = JsonEncoder.withIndent(' ' * _jsonSpacing);
          result = encoder.convert(parsed);
          break;
        case 'json_minify':
          final parsed = json.decode(input);
          result = json.encode(parsed);
          break;
      }

      setState(() {
        _outputController.text = result;
        _errorMessage = null;
      });

      // Debounce and log telemetry
      _debounceTelemetry();

    } catch (e) {
      setState(() {
        _outputController.clear();
        _errorMessage = _getFriendlyErrorMessage(e);
      });
    }
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final errStr = error.toString();
    if (errStr.contains('FormatException')) {
      if (_activeOperation == 'base64_decode') {
        return '错误：无效的 Base64 编码文本，无法正确还原。';
      }
      if (_activeOperation.startsWith('json_')) {
        return '错误：输入的 JSON 格式不合法，请检查拼写、括号或双引号。';
      }
      return '错误：格式转换失败，输入包含不规范字符。';
    }
    return '转换失败：$errStr';
  }

  void _debounceTelemetry() {
    final now = DateTime.now();
    if (_lastLoggedOp != _activeOperation || 
        _lastLoggedTime == null || 
        now.difference(_lastLoggedTime!).inSeconds > 5) {
      _lastLoggedOp = _activeOperation;
      _lastLoggedTime = now;
      try {
        ref.read(toolsAnalyticsProvider).logUsage(
          toolKey: 'dev_encoder',
          parameters: {
            'operation': _activeOperation,
            'input_length': _inputController.text.length,
            'output_length': _outputController.text.length,
          },
          status: 'success',
          durationMs: 0,
        );
      } catch (_) {}
    }
  }

  void _shareResult() {
    final text = _outputController.text.trim();
    if (text.isEmpty) return;
    Share.share(text, subject: '开发者编码转换结果');
  }

  @override
  Widget build(BuildContext context) {
    final inputLen = _inputController.text.length;
    final outputLen = _outputController.text.length;
    final inputBytes = utf8.encode(_inputController.text).length;
    final outputBytes = utf8.encode(_outputController.text).length;

    // Calculate dynamic stats
    double deltaRatio = 0;
    if (inputBytes > 0 && outputBytes > 0) {
      deltaRatio = ((outputBytes - inputBytes) / inputBytes) * 100;
    }

    final activeOpColor = _operations.firstWhere((element) => element['key'] == _activeOperation)['color'] as Color;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '开发者沙盒编码盒',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Theme Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF070B19), Color(0xFF0F1532), Color(0xFF04060C)],
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
                // 1. Selector Chips Toolbar
                const Text(
                  '🛠️ 选择编码或哈希函数',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _operations.length,
                    itemBuilder: (context, idx) {
                      final op = _operations[idx];
                      final isSelected = op['key'] == _activeOperation;
                      final opColor = op['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeOperation = op['key'];
                          });
                          _processInput();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? opColor.withOpacity(0.12)
                                : Colors.white.withOpacity(0.015),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? opColor : Colors.white.withOpacity(0.05),
                              width: 1.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: opColor.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                op['icon'],
                                color: isSelected ? opColor : Colors.white60,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                op['label'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // JSON Formatting custom options (conditional)
                if (_activeOperation == 'json_format') ...[
                  GlassCard(
                    borderColor: Colors.purpleAccent.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.space_bar_rounded, color: Colors.purpleAccent, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "JSON 缩进空格数",
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          Row(
                            children: [2, 4, 8].map((spaces) {
                              final active = _jsonSpacing == spaces;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _jsonSpacing = spaces;
                                  });
                                  _processInput();
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: active ? Colors.purpleAccent.withOpacity(0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: active ? Colors.purpleAccent : Colors.white10,
                                    ),
                                  ),
                                  child: Text(
                                    "$spaces 个空格",
                                    style: TextStyle(
                                      color: active ? Colors.purpleAccent : Colors.white30,
                                      fontSize: 11,
                                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Input Glass Card Box
                const Text(
                  '📥 贴入原始文本',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _inputController,
                        maxLines: 5,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          hintText: '请贴入待处理的字符串或JSON数据...',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _inputController.clear();
                              _outputController.clear();
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                            child: const Text(
                              '清空输入',
                              style: TextStyle(color: Colors.redAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '共 $inputLen 字符 | $inputBytes 字节',
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Error warning box (if any)
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Output Glass Card Box
                const Text(
                  '📤 变换输出结果',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _outputController,
                        maxLines: 8,
                        readOnly: true,
                        style: TextStyle(
                          color: activeOpColor,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          hintText: '格式化或编码后的结果将在这里自动展示...',
                          hintStyle: TextStyle(color: Colors.white12, fontSize: 13),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.copy_rounded, color: activeOpColor, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: '复制结果',
                                onPressed: outputLen == 0
                                    ? null
                                    : () {
                                        Clipboard.setData(ClipboardData(text: _outputController.text));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('转换结果已成功复制'),
                                            backgroundColor: activeOpColor.withOpacity(0.2),
                                          ),
                                        );
                                      },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: Icon(Icons.share_rounded, color: activeOpColor, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: '分享结果',
                                onPressed: outputLen == 0 ? null : _shareResult,
                              ),
                            ],
                          ),
                          Text(
                            '共 $outputLen 字符 | $outputBytes 字节',
                            style: const TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Comparison & Compression Stats Panel
                if (inputLen > 0 && outputLen > 0) ...[
                  const Text(
                    '📊 转换统计指标',
                    style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          "字节数增幅",
                          "${deltaRatio >= 0 ? '+' : ''}${deltaRatio.toStringAsFixed(1)}%",
                          deltaRatio == 0
                              ? Colors.white54
                              : (deltaRatio < 0 ? Colors.greenAccent : Colors.amberAccent),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          "数据压缩率",
                          _calculateRatio(inputBytes, outputBytes),
                          deltaRatio < 0 ? Colors.greenAccent : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateRatio(int originalBytes, int finalBytes) {
    if (originalBytes == 0) return '0.0%';
    final ratio = (finalBytes / originalBytes);
    if (ratio < 1.0) {
      final saved = (1.0 - ratio) * 100;
      return '节约 ${saved.toStringAsFixed(1)}%';
    } else {
      final increased = (ratio - 1.0) * 100;
      return '扩充 ${increased.toStringAsFixed(1)}%';
    }
  }
}
