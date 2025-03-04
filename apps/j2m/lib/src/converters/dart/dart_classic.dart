import 'package:change_case/change_case.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';

import '../../converter/config.dart';
import '../../converter/converter.dart';
import '../../types.dart';

/// Classic converter for Dart language.
final class DartClassicConverter extends ConverterBase {
  @override
  final DartClassicConfig config = DartClassicConfig();

  @override
  final CodeController controller = CodeController(language: dart);

  @override
  void convert() {
    final json = data;
    if (json is Json) {
      controller.fullText = _generateClass(json: json, className: 'Model');
    } else if (json case [final Json item, ...]) {
      controller.fullText = _generateClass(json: item, className: 'Model');
    }
  }

  String _generateClass({required Json json, required String className}) {
    final isMutable = getToggleValue(DartClassicConfig.mutable);
    final isAllRequired = getToggleValue(DartClassicConfig.required);
    final isAllNullable = getToggleValue(DartClassicConfig.nullable);

    final code = StringBuffer(
      'class $className {\n' // class start
      // constructor
      '  ${isMutable ? '' : 'const '}$className(',
    );

    // constructor params
    if (json.isNotEmpty) {
      code.writeln('{');
      json.forEach((key, value) {
        code.writeln('    ${isAllRequired ? 'required ' : ''}this.$key,');
      });
      code.write('  }');
    }
    code.writeln(');');
    if (json.isNotEmpty) code.writeln();

    // fields
    final classList = <String>[];
    json.forEach((key, value) {
      final type = _generateField(key, value, classList);
      code.writeln(
        '  ${isMutable ? '' : 'final '}$type${isAllNullable ? '?' : ''} $key;',
      );
    });

    code.writeln('}'); // class end

    // sub models
    for (final classDef in classList) {
      code
        ..write('\n')
        ..write(classDef);
    }
    return code.toString();
  }

  /// Generate a field and return its type.
  String _generateField(String key, dynamic value, List<String> classList) {
    final String type;
    switch (value) {
      case int():
        type = 'int';
      case double():
        type = 'double';
      case bool():
        type = 'bool';
      case String():
        type = 'String';
      case Json():
        type = key.toPascalCase();
        classList.add(_generateClass(json: value, className: type));
      case List():
        final generic =
            value.isEmpty
                ? 'dynamic'
                : _generateField(key, value[0], classList);
        type = 'List<$generic>';
      default:
        type = 'dynamic';
    }
    return type;
  }
}

final class DartClassicConfig extends ConfigBase {
  @override
  Set<String> get toggles => const {mutable, required, nullable};

  // TODO(albin): as instance variables.
  static const mutable = 'Mutable';
  static const required = 'Required';
  static const nullable = 'Nullable';
}
