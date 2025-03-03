import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/json.dart';

import 'converter/dart_converter.dart';
import 'converter/languages.dart';
import 'extensions/context_extensions.dart';
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
                Text('Json to', style: Theme.of(context).textTheme.titleMedium),
                PopupMenuButton(
                  borderRadius: BorderRadius.circular(8),
                  onSelected: print,
                  itemBuilder: (context) {
                    return Languages.values.map((e) {
                      return PopupMenuItem(value: e, child: Text(e.label));
                    }).toList();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ).copyWith(right: 2),
                    child: Row(
                      children: [
                        Text(
                          'Dart',
                          style: context.tt.titleMedium?.copyWith(
                            color: context.cs.primary,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: context.cs.primary),
                      ],
                    ),
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
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                shape: const RoundedRectangleBorder(),
                              ),
                              onPressed: _convert,
                              child: const Text('Convert'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // output editor
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: OutputView(converter: _converter)),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                shape: const RoundedRectangleBorder(),
                              ),
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
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Error: ${e.message}'), showCloseIcon: true),
        );
    } catch (e) {
      log('error $e');
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: _converter.controller.fullText),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard!'),
          showCloseIcon: true,
        ),
      );
  }
}
