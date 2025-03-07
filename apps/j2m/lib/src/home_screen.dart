import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/json.dart';

import 'converter/base.dart';
import 'converter/language_enum.dart';
import 'converter/variant.dart';
import 'extensions/context_extensions.dart';
import 'input_view.dart';
import 'output_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _modelNameController = TextEditingController(text: 'Model');

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

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void dispose() {
    _modelNameController.dispose();
    _inputController.dispose();
    _converter.dispose();
    super.dispose();
  }

  Language _language = Language.dart;
  Variant _variant = Variant.dartClassic;
  ConverterBase _converter = Variant.dartClassic.converter();

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

                // language list
                PopupMenuButton(
                  borderRadius: BorderRadius.circular(8),
                  onSelected: _onChangeLanguage,
                  initialValue: _language,
                  itemBuilder: (context) {
                    return Language.values.map((e) {
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
                          _language.label,
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

                // variants
                Row(
                  spacing: 8,
                  children: [
                    for (final v in Variant.ofLanguage(_language))
                      ChoiceChip(
                        label: Text(v.name),
                        selected: _variant == v,
                        onSelected: (value) {
                          if (value) _onChangeVariant(v);
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // toggles
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // model name input
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _modelNameController,
                    decoration: const InputDecoration(
                      hintText: 'ModelName',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),

                // toggles
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      for (final field in _converter.toggles)
                        _buildButton(
                          label: field.name,
                          value: field.value,
                          onTap: () {
                            field.toggle();
                            _converter.convert();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

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

  void _onChangeLanguage(Language lang) {
    if (lang == _language) return;
    setState(() {
      _language = lang;
      _variant = Variant.ofLanguage(lang).first;
      _converter.dispose();
      _converter = _variant.converter();
    });
    _convert();
  }

  void _onChangeVariant(Variant variant) {
    setState(() {
      _variant = variant;
      _converter.dispose();
      _converter = variant.converter();
    });
    _convert();
  }

  TextButton _buildButton({
    required String label,
    required bool value,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Checkbox(value: value, onChanged: (_) => onTap()),
        ],
      ),
    );
  }

  // TODO(albin): cache json and load data on change
  void _convert() {
    final text = _inputController.fullText.trim();
    if (text.isEmpty) return;
    try {
      final json = jsonDecode(text);
      _inputController.fullText = _encoder.convert(json);
      _converter
        ..setJson(json)
        ..modelName = _modelNameController.text.trim()
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
