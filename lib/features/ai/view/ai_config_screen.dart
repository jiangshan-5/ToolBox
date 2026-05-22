import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/ai_config_provider.dart';

class AiConfigScreen extends ConsumerStatefulWidget {
  const AiConfigScreen({super.key});

  @override
  ConsumerState<AiConfigScreen> createState() => _AiConfigScreenState();
}

class _AiConfigScreenState extends ConsumerState<AiConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedProvider;
  late TextEditingController _keyController;
  late TextEditingController _urlController;
  late TextEditingController _modelController;
  bool _testingConnection = false;
  bool _obscureApiKey = true;

  final Map<String, List<String>> _modelSuggestions = {
    'freemodel': [
      'gpt-5.5',
      'gpt-5.4',
      'gpt-5.4-mini',
    ],
    'siliconflow': [
      'deepseek-ai/DeepSeek-V3',
      'deepseek-ai/DeepSeek-R1',
      'THUDM/glm-4-9b-chat',
      'Qwen/Qwen2.5-7B-Instruct',
    ],
    'deepseek': [
      'deepseek-chat',
      'deepseek-reasoner',
    ],
    'gemini': [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ],
    'openai': [
      'gpt-4o-mini',
      'gpt-4o',
      'gpt-3.5-turbo',
    ],
  };

  final Map<String, String> _defaultUrls = {
    'freemodel': 'https://api.freemodel.dev/v1',
    'siliconflow': 'https://api.siliconflow.cn/v1',
    'deepseek': 'https://api.deepseek.com',
    'gemini': '',
    'openai': 'https://api.openai.com/v1',
  };

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
    _selectedProvider = config.provider;
    _keyController = TextEditingController(text: config.apiKey);
    _urlController = TextEditingController(text: config.baseUrl);
    _modelController = TextEditingController(text: config.model);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _urlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _onProviderChanged(String provider) {
    setState(() {
      _selectedProvider = provider;
      if (provider == 'mock') {
        _keyController.clear();
        _urlController.clear();
        _modelController.clear();
      } else {
        _urlController.text = _defaultUrls[provider] ?? '';
        final suggestions = _modelSuggestions[provider] ?? [];
        if (suggestions.isNotEmpty) {
          _modelController.text = suggestions.first;
        } else {
          _modelController.clear();
        }
        if (provider == 'freemodel' && _keyController.text.trim().isEmpty) {
          _keyController.text = 'fe_oa_c8ad66407d07ea60589e1b1482bc2258a0fe3a7d41b86037';
        }
      }
    });
  }

  Future<void> _testConnection() async {
    if (_selectedProvider == 'mock') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('模拟模式无需测试连接。'),
          backgroundColor: Colors.blueAccent,
        ),
      );
      return;
    }

    if (_keyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入 API Key 以进行连接测试。'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _testingConnection = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final response = await apiClient.instance.post(
        '/ai/chat',
        data: {
          'message': 'ping',
          'history': [],
        },
        options: Options(
          headers: {
            'X-AI-Provider': _selectedProvider,
            'X-AI-Key': _keyController.text.trim(),
            'X-AI-Base-URL': _urlController.text.trim(),
            'X-AI-Model': _modelController.text.trim(),
          },
        ),
      );

      final reply = response.data['reply'] as String;
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                SizedBox(width: 10),
                Text('测试成功', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI 接口已成功联通！返回响应：', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reply,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('太棒了', style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException) {
        errMsg = e.error?.toString() ?? e.response?.data?['detail']?.toString() ?? '请求异常 (状态码: ${e.response?.statusCode})';
      }
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('联通失败', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('连接大模型时遇到错误，请检查配置或余额：', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errMsg,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回检查', style: TextStyle(color: Colors.blueAccent)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _testingConnection = false;
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(aiConfigProvider.notifier).updateConfig(
            provider: _selectedProvider,
            apiKey: _keyController.text.trim(),
            baseUrl: _urlController.text.trim(),
            model: _modelController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI 配置已成功保存！'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _modelSuggestions[_selectedProvider] ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AI 助手云端配置', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C1B),
              Color(0xFF140D26),
              Color(0xFF0A0714),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '选择您的 AI 驱动引擎',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProviderSelectors(),
                  const SizedBox(height: 24),
                  if (_selectedProvider != 'mock') ...[
                    const Text(
                      '接口配置详情',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Base URL field
                            TextFormField(
                              controller: _urlController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'API Base URL',
                                labelStyle: const TextStyle(color: Colors.white60),
                                hintText: '请输入 API 基址 (例如: https://api.openai.com/v1)',
                                hintStyle: const TextStyle(color: Colors.white30),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.02),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // API Key field
                            TextFormField(
                              controller: _keyController,
                              style: const TextStyle(color: Colors.white),
                              obscureText: _obscureApiKey,
                              autofillHints: null,
                              decoration: InputDecoration(
                                labelText: 'API Key',
                                labelStyle: const TextStyle(color: Colors.white60),
                                hintText: '请输入您的私人 API 密钥',
                                hintStyle: const TextStyle(color: Colors.white30),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: Colors.white60,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureApiKey = !_obscureApiKey;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.02),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'API Key 不能为空';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            // Model Identifier field
                            TextFormField(
                              controller: _modelController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '模型标识符 (Model ID)',
                                labelStyle: const TextStyle(color: Colors.white60),
                                hintText: '请输入大语言模型具体 ID',
                                hintStyle: const TextStyle(color: Colors.white30),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blueAccent),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.02),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '模型标识符不能为空';
                                }
                                return null;
                              },
                            ),
                            if (suggestions.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              const Text(
                                '推荐模型选择 (可点击一键填入)：',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: suggestions.map((model) {
                                  final isSelected = _modelController.text == model;
                                  return ChoiceChip(
                                    label: Text(
                                      model.contains('/') ? model.split('/').last : model,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: Colors.cyanAccent,
                                    backgroundColor: Colors.white.withOpacity(0.05),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _modelController.text = model;
                                        });
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // Mock explanation card
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.science_rounded,
                                color: Colors.blueAccent,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '本地模拟模式 (Mock Mode)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '当前应用处于离线离网调试模式。所有 AI 对话和文本处理操作均使用本地固定的预设模版回复。\n\n'
                              '您可以随时在上方选择 SiliconFlow (极力推荐！国内超低延迟、永久免费 DeepSeek 额度)、官方 DeepSeek 或 Gemini API，输入您的专属 API Key，即可直接在此体验真正的云端模型！',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                  // Connection test and Save Buttons
                  if (_selectedProvider != 'mock') ...[
                    OutlinedButton.icon(
                      onPressed: _testingConnection ? null : _testConnection,
                      icon: _testingConnection
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                            )
                          : const Icon(Icons.network_ping_rounded, color: Colors.blueAccent),
                      label: Text(
                        _testingConnection ? '正在联通测试...' : '测试 API 连通性',
                        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.blueAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      '保存并返回',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderSelectors() {
    final providers = [
      {
        'id': 'freemodel',
        'name': 'FreeModel AI',
        'sub': '极速 GPT-5.5 体验 (深度扩容)',
        'icon': Icons.bolt_rounded,
        'color': Colors.amber,
      },
      {
        'id': 'siliconflow',
        'name': 'SiliconFlow',
        'sub': '硅基流动 (推荐)',
        'icon': Icons.offline_bolt_rounded,
        'color': Colors.cyanAccent,
      },
      {
        'id': 'deepseek',
        'name': 'DeepSeek',
        'sub': '深度求索 (官方)',
        'icon': Icons.psychology_rounded,
        'color': Colors.blueAccent,
      },
      {
        'id': 'gemini',
        'name': 'Gemini',
        'sub': '谷歌 Gemini',
        'icon': Icons.lens_blur_rounded,
        'color': Colors.purpleAccent,
      },
      {
        'id': 'openai',
        'name': 'Custom/OpenAI',
        'sub': '自定义兼容网关',
        'icon': Icons.settings_suggest_rounded,
        'color': Colors.orangeAccent,
      },
      {
        'id': 'mock',
        'name': 'Mock Mode',
        'sub': '本地模拟调试',
        'icon': Icons.science_rounded,
        'color': Colors.grey,
      },
    ];

    return Column(
      children: providers.map((prov) {
        final isSelected = _selectedProvider == prov['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? (prov['color'] as Color) : Colors.white.withOpacity(0.08),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (prov['color'] as Color).withOpacity(0.15),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: GlassCard(
              borderColor: Colors.transparent,
              onTap: () => _onProviderChanged(prov['id'] as String),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      prov['icon'] as IconData,
                      color: isSelected ? (prov['color'] as Color) : Colors.white60,
                      size: 26,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prov['name'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            prov['sub'] as String,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: prov['color'] as Color,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
