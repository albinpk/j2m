import 'package:flutter/material.dart';

import 'converter/base.dart';

class OutputView extends StatelessWidget {
  const OutputView({required this.converter, this.wrapText = false, super.key});

  /// The language converter.
  final ConverterBase converter;

  /// If true, the text will be wrapped to fit the available width.
  final bool wrapText;

  @override
  Widget build(BuildContext context) {
    final textField = TextField(
      controller: converter.controller,
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
