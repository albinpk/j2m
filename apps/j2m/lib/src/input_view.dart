import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

class InputView extends StatelessWidget {
  const InputView({required this.controller, super.key});

  final CodeController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(8),
        ),
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'RobotoMono'),
      ),
    );
  }
}
