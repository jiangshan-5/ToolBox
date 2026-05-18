import 'dart:math';
import 'package:flutter/material.dart';

class RandomizerScreen extends StatefulWidget {
  const RandomizerScreen({super.key});

  @override
  State<RandomizerScreen> createState() => _RandomizerScreenState();
}

class _RandomizerScreenState extends State<RandomizerScreen> {
  int _result = 0;
  final _random = Random();

  void _generate() {
    setState(() {
      _result = _random.nextInt(100) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Random Number')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Your lucky number is:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Text(
              '$_result',
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('GENERATE'),
            ),
          ],
        ),
      ),
    );
  }
}
