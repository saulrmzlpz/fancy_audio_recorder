import 'dart:developer';

import 'package:fancy_audio_recorder/fancy_audio_recorder.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? test;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fancy Sample App'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AudioRecorderButton(
                maxRecordDuration: const Duration(seconds: 80),
                onRecordComplete: (value) {
                  log('$value');
                  setState(() {
                    test = value;
                  });
                },
              ),
              Text('$test'),
            ],
          ),
        ),
      ),
    );
  }
}
