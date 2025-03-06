import 'package:change_case/change_case.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';

import '../../converter/base.dart';
import '../../types.dart';

/// Classic converter for Dart language.
final class DartClassicConverter extends ConverterBase<DartClassicConfig> {
  @override
  late final DartClassicConfig config = DartClassicConfig(this);

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
    final isMutable = config.mutable();
    final isRequired = config.required();
    final isNullable = config.nullable();
    final toString = config.stringify();
    final copyWith = config.copyWith();
    final equality = config.equality();

    final code = StringBuffer(
        isMutable
            ? ''
            : "import 'package:flutter/foundation.dart';\n\n"
                '@immutable\n',
      )
      // class start
      ..write(
        'class $className {\n'
        // constructor
        '  ${isMutable ? '' : 'const '}$className(',
      );

    // constructor params
    if (json.isNotEmpty) {
      code.writeln('{');
      json.forEach((key, value) {
        code.writeln('    ${isRequired ? 'required ' : ''}this.$key,');
      });
      code.write('  }');
    }
    code.writeln(');');
    if (json.isNotEmpty) code.writeln();

    // map of keyName => Type
    final types = <String, String>{};

    // fields
    final classList = <String>[];
    json.forEach((key, value) {
      final type = _generateField(key, value, classList);
      types[key] = type;
      code.writeln(
        '  ${isMutable ? '' : 'final '}$type${isNullable ? '?' : ''} $key;',
      );
    });

    // toString
    if (toString) {
      code
        ..writeln('\n  @override')
        ..writeln(
          '  String toString() =>\n'
          "      '$className('\n"
          "      ${json.keys.map((e) => "' $e: \$$e").join(",'\n      ")}'\n"
          "      ')';",
        );
    }

    // copyWith
    if (copyWith) {
      code.writeln(
        '\n  $className copyWith({\n'
        '    ${json.keys.map((e) => '${types[e]}? $e,').join('\n    ')}\n'
        '  }) => $className(\n'
        '    ${json.keys.map((e) => '$e: $e ?? this.$e,').join('\n    ')}\n'
        '  );',
      );
    }

    // equality
    if (equality) {
      code.writeln(
        '\n  @override\n'
        '  bool operator ==(Object other) {\n'
        '    if (identical(this, other)) return true;\n'
        '    return other is $className &&\n'
        '        ${json.keys.map((e) => 'other.$e == $e').join(' &&\n        ')};\n'
        '  }\n\n'
        '  @override\n'
        '  int get hashCode =>\n'
        '      ${json.keys.map((e) => '$e.hashCode').join(' ^\n      ')};',
      );
    }

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

  @override
  void onToggleChange(String key, bool value) {
    if (key == config.mutable.name) {
      if (value) {
        if (!config.nullable.value) {
          config.required.value = true;
        }
        config.equality.value = false;
      } else if (!config.nullable.value) {
        config.required.value = true;
      }
    } else if (key == config.required.name) {
      if (!value) {
        config.nullable.value = true;
      }
    } else if (key == config.nullable.name) {
      if (!value) {
        config.required.value = true;
      }
    } else if (key == config.equality.name) {
      if (value) {
        config.mutable.value = false;
      }
    }
  }
}

final class DartClassicConfig extends ConfigBase {
  DartClassicConfig(super.converter);

  late final mutable = toggle('Mutable');
  late final required = toggle('Required', initial: true);
  late final nullable = toggle('Nullable');
  late final stringify = toggle('toString');
  late final copyWith = toggle('copyWith');
  late final equality = toggle('Equality');

  @override
  Set<Toggle> get toggles => {
    mutable,
    required,
    nullable,
    stringify,
    copyWith,
    equality,
  };
}
