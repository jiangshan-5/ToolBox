import 'package:flutter/material.dart';

final Map<String, Map<String, dynamic>> breathingConfigs = {
  '4-7-8': {
    'name': '4-7-8 呼吸减压法',
    'desc': '4秒吸气，7秒屏息，8秒呼气。专为排解焦虑、平心静气及深度助眠研发。',
    'phases': ['inhale', 'hold', 'exhale'],
    'durations': {'inhale': 4, 'hold': 7, 'exhale': 8},
    'glow': Colors.purpleAccent,
  },
  'box': {
    'name': '等时盒式呼吸法',
    'desc': '吸气、屏息、呼气、呼后屏息均等时（各4秒）。特种部队压力重置极简训练。',
    'phases': ['inhale', 'hold', 'exhale', 'hold2'],
    'durations': {'inhale': 4, 'hold': 4, 'exhale': 4, 'hold2': 4},
    'glow': Colors.tealAccent,
  },
  'equal': {
    'name': '5-5 均衡平静法',
    'desc': '5秒吸气，5秒呼气。帮助均匀调息，减缓心率，促使大脑迅速恢复清明。',
    'phases': ['inhale', 'exhale'],
    'durations': {'inhale': 5, 'exhale': 5},
    'glow': Colors.cyanAccent,
  },
};
