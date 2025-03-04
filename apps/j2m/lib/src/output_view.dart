import 'package:flutter/material.dart';

import 'converter/base.dart';

class OutputView extends StatelessWidget {
  const OutputView({required this.converter, super.key});

  final ConverterBase converter;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: converter.controller,
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
