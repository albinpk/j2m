import 'package:flutter/material.dart';

import 'converter/converter.dart';

class OutputView extends StatelessWidget {
  const OutputView({required this.converter, super.key});

  final ConverterBase converter;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: converter.controller,
      // decoration: const InputDecoration(border: OutlineInputBorder()),
      maxLines: null,
      expands: true,
      style: const TextStyle(fontFamily: 'RobotoMono'),
    );
  }
}
