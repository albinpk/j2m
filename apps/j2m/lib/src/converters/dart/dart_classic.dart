import 'package:change_case/change_case.dart';
import 'package:flutter/foundation.dart';
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
    if (data case final Json json || [final Json json, ...]) {
      final importList = <String>{}; // mutable
      final code = _generateClass(
        json: json,
        className: modelName,
        importList: importList,
      );
      controller.fullText =
          importList.isNotEmpty ? '${importList.join('\n')}\n\n$code' : code;
    } else {
      debugPrint('Invalid data type "${data.runtimeType}"');
    }
  }

  String _generateClass({
    required Json json,
    required String className,
    required Set<String> importList,
  }) {
    if (json.isEmpty) return '';

    final isMutable = config.mutable();
    final isRequired = config.required();
    final isNullable = config.nullable();
    final toString = config.stringify();
    final copyWith = config.copyWith();
    final equality = config.equality();

    if (!isMutable) {
      importList.add("import 'package:flutter/foundation.dart';");
    }

    final code =
        StringBuffer(isMutable ? '' : '@immutable\n')
          // class start
          ..write(
            'class $className {\n'
            // constructor
            '  ${isMutable ? '' : 'const '}$className(',
          )
          // constructor params
          ..writeln('{');
    json.forEach((key, value) {
      code.writeln('    ${isRequired ? 'required ' : ''}this.$key,');
    });
    code.write('  });\n\n');

    // map of keyName => Type
    final types = <String, String>{};

    // fields
    final classList = <String>[];
    json.forEach((key, value) {
      final type = _generateField(
        key: key,
        value: value,
        classList: classList,
        importList: importList,
      );
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
  String _generateField({
    required String key,
    required dynamic value,
    required List<String> classList,
    required Set<String> importList,
  }) {
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
        classList.add(
          _generateClass(json: value, className: type, importList: importList),
        );
      case List():
        final generic =
            value.isEmpty
                ? 'dynamic'
                : _generateField(
                  key: key,
                  value: value[0],
                  classList: classList,
                  importList: importList,
                );
        type = 'List<$generic>';
      default:
        type = 'dynamic';
    }
    return type;
  }

  /*
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
  */
}

final class DartClassicConfig extends ConfigBase {
  DartClassicConfig(super.converter);

  late final Toggle mutable = toggle(
    'Mutable',
    onChange: (value) {
      if (value) {
        equality.value = false;
        if (!nullable.value) required.value = true;
      } else if (!nullable.value) {
        required.value = true;
      }
    },
  );

  late final Toggle required = toggle(
    'Required',
    initial: true,
    onChange: (value) {
      if (!value) nullable.value = true;
    },
  );

  late final Toggle nullable = toggle(
    'Nullable',
    onChange: (value) {
      if (!value) required.value = true;
    },
  );
  late final Toggle stringify = toggle('toString');

  late final Toggle copyWith = toggle('copyWith');

  late final Toggle equality = toggle(
    'Equality',
    onChange: (value) {
      if (value) mutable.value = false;
    },
  );

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
