import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

class InputView extends StatelessWidget {
  const InputView({required this.controller, this.wrapText = false, super.key});

  /// The controller to use for the text field.
  final CodeController controller;

  /// If true, the text will be wrapped to fit the available width.
  final bool wrapText;

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      controller: controller,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(8),
      ),
      maxLines: null,
      expands: true,
      style: const TextStyle(fontFamily: 'RobotoMono'),
    );

    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (wrapText) return textField;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: IntrinsicWidth(child: textField),
            ),
          );
        },
      ),
    );
  }
}
