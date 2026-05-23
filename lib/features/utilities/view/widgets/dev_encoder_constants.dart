import 'package:flutter/material.dart';

class DevEncoderOperation {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const DevEncoderOperation({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const List<DevEncoderOperation> devOperations = [
  DevEncoderOperation(key: 'base64_encode', label: 'Base64 编码', icon: Icons.enhanced_encryption_rounded, color: Colors.cyanAccent),
  DevEncoderOperation(key: 'base64_decode', label: 'Base64 解码', icon: Icons.no_encryption_gmailerrorred_rounded, color: Colors.cyanAccent),
  DevEncoderOperation(key: 'url_encode', label: 'URL 编码', icon: Icons.link_rounded, color: Colors.greenAccent),
  DevEncoderOperation(key: 'url_decode', label: 'URL 解码', icon: Icons.link_off_rounded, color: Colors.greenAccent),
  DevEncoderOperation(key: 'hex_encode', label: 'Hex 编码', icon: Icons.grid_3x3_rounded, color: Colors.tealAccent),
  DevEncoderOperation(key: 'hex_decode', label: 'Hex 解码', icon: Icons.grid_off_rounded, color: Colors.tealAccent),
  DevEncoderOperation(key: 'md5', label: 'MD5 哈希', icon: Icons.fingerprint_rounded, color: Colors.orangeAccent),
  DevEncoderOperation(key: 'sha256', label: 'SHA-256 哈希', icon: Icons.security_rounded, color: Colors.pinkAccent),
  DevEncoderOperation(key: 'timestamp_conv', label: '时间戳转换', icon: Icons.schedule_rounded, color: Colors.deepOrangeAccent),
  DevEncoderOperation(key: 'json_format', label: 'JSON 格式化', icon: Icons.format_align_left_rounded, color: Colors.purpleAccent),
  DevEncoderOperation(key: 'json_minify', label: 'JSON 压缩', icon: Icons.compress_rounded, color: Colors.amberAccent),
];
