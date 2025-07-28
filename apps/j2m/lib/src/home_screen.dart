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
import 'widgets/app_info_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future(_convert);
    _inputController.addListener(_onChange);

    // for development
    // Timer.periodic(const Duration(milliseconds: 200), (t) => _convert());
  }

  final _modelNameController = TextEditingController(
    text: ConverterBase.defaultModelName,
  );

  final _inputController = CodeController(
    text: '''
{
  "name": "John Doe",
  "email": "johndoe@example.com",
  "age": 30,
  "profile": {
    "isActive": true,
    "create_at": "2023-03-22T00:00:00.000Z"
  }
}
''',
    language: json,
  );

  String _input = '';
  void _onChange() {
    if (_input != _inputController.fullText) {
      _convert(format: false);
      _input = _inputController.fullText;
    }
  }

  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void dispose() {
    _modelNameController.dispose();
    _inputController.dispose();
    _converter.dispose();
    super.dispose();
  }

  Language _language = Language.dart;
  Variant _variant = Variant.ofLanguage(Language.dart).first;
  late ConverterBase _converter = _variant.converter();

  bool _wrapInputText = false;
  bool _wrapOutputText = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.onSurface.withValues(alpha: 0.5),
        ),
      ),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20).copyWith(bottom: 0),
          child: Column(
            children: [
              // top bar
              Row(
                children: [
                  Text('Json to', style: theme.textTheme.titleMedium),

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
                          Icon(
                            Icons.arrow_drop_down,
                            color: context.cs.primary,
                          ),
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
                      onChanged: (_) => _convert(),
                      decoration: const InputDecoration(
                        hintText: 'Model name',
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
                        child: Stack(
                          children: [
                            InputView(
                              controller: _inputController,
                              wrapText: _wrapInputText,
                            ),

                            // generate button, bottom right
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: FloatingActionButton.extended(
                                  onPressed: _convert,
                                  icon: const Icon(
                                    Icons.keyboard_double_arrow_right_rounded,
                                  ),
                                  label: const Text('Generate'),
                                ),
                              ),
                            ),

                            // top right
                            Align(
                              alignment: Alignment.topRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // copy input
                                  IconButton(
                                    tooltip: 'Copy',
                                    onPressed: _copyInput,
                                    icon: const Icon(Icons.copy_rounded),
                                  ),

                                  // text wrap
                                  IconButton(
                                    tooltip: 'Wrap text',
                                    color: _wrapInputText
                                        ? colors.onSurface
                                        : null,
                                    onPressed: () {
                                      setState(
                                        () => _wrapInputText = !_wrapInputText,
                                      );
                                    },
                                    icon: const Icon(Icons.wrap_text_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // output editor
                      Expanded(
                        child: Stack(
                          children: [
                            OutputView(
                              converter: _converter,
                              wrapText: _wrapOutputText,
                            ),

                            // copy button
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: FloatingActionButton.extended(
                                  onPressed: _copyOutput,
                                  icon: const Icon(Icons.copy_rounded),
                                  label: const Text('Copy'),
                                ),
                              ),
                            ),

                            // text wrap button
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                tooltip: 'Wrap text',
                                color: _wrapOutputText
                                    ? colors.onSurface
                                    : null,
                                onPressed: () {
                                  setState(
                                    () => _wrapOutputText = !_wrapOutputText,
                                  );
                                },
                                icon: const Icon(Icons.wrap_text_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // info
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Info',
                    onPressed: _showInfo,
                    icon: const Icon(Icons.info_outline),
                  ),
                ],
              ),
            ],
          ),
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
    required bool? value,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Checkbox(tristate: true, value: value, onChanged: (_) => onTap()),
        ],
      ),
    );
  }

  // TODO(albin): cache json and load data on change
  void _convert({bool format = true}) {
    final text = _inputController.fullText.trim();
    if (text.isEmpty) return;
    try {
      final json = jsonDecode(text);
      if (format) {
        _inputController.fullText = '${_encoder.convert(json)}\n';
      }
      _converter
        ..setJsonFromDecoded(json)
        ..modelName = _modelNameController.text
        ..convert();
      setState(() {});
    } on FormatException catch (e) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('Error: ${e.message}'), showCloseIcon: true),
        );
    } catch (e) {
      log('error $e');
    }
  }

  Future<void> _copyInput() async {
    await Clipboard.setData(ClipboardData(text: _inputController.fullText));
    _showSnackbar('Copied to clipboard!');
  }

  Future<void> _copyOutput() async {
    await Clipboard.setData(
      ClipboardData(text: _converter.controller.fullText),
    );
    _showSnackbar('Copied to clipboard!');
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message), showCloseIcon: true));
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => const AppInfoDialog(),
    );
  }
}
