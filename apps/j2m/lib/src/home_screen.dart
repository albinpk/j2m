import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/json.dart';

import 'converter/dart_converter.dart';
import 'input_view.dart';
import 'output_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _inputController = CodeController(
    text: '''
{
  "id": 1,
  "name": "John Doe",
  "email": "johndoe@example.com",
  "age": 30,
  "isActive": true
}
''',
    language: json,
  );

  final _converter = JsonToDartConverter();

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void dispose() {
    _inputController.dispose();
    _converter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // top bar
            Row(
              children: [
                Tooltip(
                  message: 'JSON to Model',
                  child: Text(
                    'J2M',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Spacer(),

                for (final field in _converter.toggles)
                  _buildButton(
                    label: field.label,
                    value: field.value,
                    onTap: () {
                      field.change();
                      _converter.convert();
                      setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // editor
            Expanded(
              child: CodeTheme(
                data: CodeThemeData(styles: draculaTheme),
                child: Row(
                  children: [
                    // input editor
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: InputView(controller: _inputController),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: FilledButton(
                              onPressed: _convert,
                              child: const Text('Convert'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 20),

                    // output editor
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: OutputView(converter: _converter)),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: FilledButton(
                              onPressed: _copy,
                              child: const Text('Copy'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextButton _buildButton({
    required String label,
    required bool value,
    required VoidCallback? onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      child: Row(
        children: [
          Text(label),
          Checkbox(
            value: value,
            onChanged: onTap == null ? null : (value) => onTap.call(),
          ),
        ],
      ),
    );
  }

  void _convert() {
    final text = _inputController.fullText;
    try {
      final json = jsonDecode(text);
      _inputController.fullText = _encoder.convert(json);
      _converter
        ..setData(json)
        ..convert();
      setState(() {});
    } catch (e) {
      log('error $e');
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _converter.controller.fullText));
  }
}
