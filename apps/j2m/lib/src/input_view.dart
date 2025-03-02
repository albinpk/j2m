import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

class InputView extends StatelessWidget {
  const InputView({required this.controller, super.key});

  final CodeController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      // decoration: const InputDecoration(border: OutlineInputBorder()),
      maxLines: null,
      expands: true,
      style: const TextStyle(fontFamily: 'RobotoMono'),
    );
  }
}
