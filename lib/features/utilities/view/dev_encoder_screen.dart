import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto/crypto.dart';

import '../../../features/dashboard/provider/tools_provider.dart';
import 'widgets/dev_encoder_constants.dart';
import 'widgets/dev_selector_chips.dart';
import 'widgets/dev_json_spacing_options.dart';
import 'widgets/dev_input_panel.dart';
import 'widgets/dev_output_panel.dart';
import 'widgets/dev_stats_panel.dart';
import 'widgets/dev_error_box.dart';

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

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_processInput);

    // Initial seed input just to make it interesting
    _inputController.text =
        '{"name": "Cyber Toolbox", "version": "1.0", "status": "online"}';
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
          final cleaned = input.replaceAll(RegExp(r'\s+'), '');
          result = utf8.decode(base64.decode(cleaned));
          break;
        case 'url_encode':
          result = Uri.encodeComponent(input);
          break;
        case 'url_decode':
          result = Uri.decodeComponent(input);
          break;
        case 'hex_encode':
          final bytes = utf8.encode(input);
          result = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          break;
        case 'hex_decode':
          var cleanedHex = input.replaceAll(RegExp(r'[\s:]+'), '');
          if (cleanedHex.startsWith('0x') || cleanedHex.startsWith('0X')) {
            cleanedHex = cleanedHex.substring(2);
          }
          if (cleanedHex.length % 2 != 0) {
            throw const FormatException('Hex 字符串长度必须是偶数');
          }
          if (!RegExp(r'^[0-9a-fA-F]*$').hasMatch(cleanedHex)) {
            throw FormatException('输入包含非法的十六进制字符');
          }
          final decodedBytes = <int>[];
          for (var i = 0; i < cleanedHex.length; i += 2) {
            final byteString = cleanedHex.substring(i, i + 2);
            final byte = int.parse(byteString, radix: 16);
            decodedBytes.add(byte);
          }
          result = utf8.decode(decodedBytes);
          break;
        case 'md5':
          final bytes = utf8.encode(input);
          result = md5.convert(bytes).toString();
          break;
        case 'sha256':
          final bytes = utf8.encode(input);
          result = sha256.convert(bytes).toString();
          break;
        case 'timestamp_conv':
          final trimmed = input.trim();
          final isNumeric = RegExp(r'^\d+$').hasMatch(trimmed);
          if (isNumeric) {
            final val = int.parse(trimmed);
            DateTime dt;
            if (trimmed.length <= 10) {
              dt = DateTime.fromMillisecondsSinceEpoch(val * 1000);
            } else {
              dt = DateTime.fromMillisecondsSinceEpoch(val);
            }
            result =
                '本地时间 (Local Time):\n${dt.toLocal().toString()}\n\nUTC 时间 (UTC Time):\n${dt.toUtc().toIso8601String()}';
          } else {
            final parsed = DateTime.tryParse(trimmed);
            if (parsed == null) {
              throw FormatException('非法的日期格式');
            }
            final sec = parsed.millisecondsSinceEpoch ~/ 1000;
            final ms = parsed.millisecondsSinceEpoch;
            result =
                '秒级时间戳 (Seconds):\n$sec\n\n毫秒级时间戳 (Milliseconds):\n$ms\n\nISO 8601 格式:\n${parsed.toUtc().toIso8601String()}';
          }
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
      if (_activeOperation == 'hex_decode') {
        if (errStr.contains('偶数')) {
          return '错误：十六进制编码字符长度必须为偶数（每个字节 2 个字符）。';
        }
        if (errStr.contains('非法')) {
          return '错误：输入中包含非法的十六进制字符（仅允许 0-9、a-f、A-F）。';
        }
        return '错误：无效的 Hex 编码文本，无法正确还原。';
      }
      if (_activeOperation == 'timestamp_conv') {
        return '错误：非法的日期格式。请输入 Unix 时间戳（秒或毫秒），或标准日期时间格式（例如 2026-05-22 10:00:00）。';
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
        ref
            .read(toolsAnalyticsProvider)
            .logUsage(
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

  @override
  Widget build(BuildContext context) {
    final inputLen = _inputController.text.length;
    final outputLen = _outputController.text.length;
    final inputBytes = utf8.encode(_inputController.text).length;
    final outputBytes = utf8.encode(_outputController.text).length;
    double deltaRatio = 0;
    if (inputBytes > 0 && outputBytes > 0) {
      deltaRatio = ((outputBytes - inputBytes) / inputBytes) * 100;
    }

    final activeOp = devOperations.firstWhere(
      (element) => element.key == _activeOperation,
    );
    final activeOpColor = activeOp.color;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 800;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '开发者沙盒编码盒',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF070B19),
                  Color(0xFF0F1532),
                  Color(0xFF04060C),
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
                DevSelectorChips(
                  activeOperation: _activeOperation,
                  onOperationChanged: (op) {
                    setState(() {
                      _activeOperation = op;
                    });
                    _processInput();
                  },
                ),
                const SizedBox(height: 18),
                if (_activeOperation == 'json_format') ...[
                  DevJsonSpacingOptions(
                    jsonSpacing: _jsonSpacing,
                    onJsonSpacingChanged: (spaces) {
                      setState(() {
                        _jsonSpacing = spaces;
                      });
                      _processInput();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (isWide) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DevInputPanel(
                              inputController: _inputController,
                              inputLen: inputLen,
                              inputBytes: inputBytes,
                              isWide: true,
                              onClear: () {
                                _inputController.clear();
                                _outputController.clear();
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              DevErrorBox(errorMessage: _errorMessage!),
                            ],
                            if (inputLen > 0 && outputLen > 0) ...[
                              const SizedBox(height: 20),
                              DevStatsPanel(
                                inputBytes: inputBytes,
                                outputBytes: outputBytes,
                                deltaRatio: deltaRatio,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DevOutputPanel(
                              outputController: _outputController,
                              outputLen: outputLen,
                              outputBytes: outputBytes,
                              activeOpColor: activeOpColor,
                              isWide: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  DevInputPanel(
                    inputController: _inputController,
                    inputLen: inputLen,
                    inputBytes: inputBytes,
                    isWide: false,
                    onClear: () {
                      _inputController.clear();
                      _outputController.clear();
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    DevErrorBox(errorMessage: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  DevOutputPanel(
                    outputController: _outputController,
                    outputLen: outputLen,
                    outputBytes: outputBytes,
                    activeOpColor: activeOpColor,
                    isWide: false,
                  ),
                  const SizedBox(height: 20),
                  if (inputLen > 0 && outputLen > 0)
                    DevStatsPanel(
                      inputBytes: inputBytes,
                      outputBytes: outputBytes,
                      deltaRatio: deltaRatio,
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
}
