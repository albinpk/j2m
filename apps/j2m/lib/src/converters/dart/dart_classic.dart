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
  String propCasing(String prop) => prop.toCamelCase();

  @override
  String classCasing(String className) => className.toPascalCase();

  @override
  String generateCode() {
    final importList = <String>{}; // mutable
    final code = _generateClass(
      json: json,
      className: modelName,
      importList: importList,
    );
    return importList.isNotEmpty ? '${importList.join('\n')}\n\n$code' : code;
  }

  @override
  List<Line> generateLines() {
    return generateCode().split('\n').map(Line.new).toList();
  }

  String _generateClass({
    required Json json,
    required String className,
    required Set<String> importList,
  }) {
    if (json.isEmpty) return '';
    newClass(className);

    final isMutable = config.mutable();
    final isRequired = config.required();
    final isNullable = config.nullable();
    final toString = config.stringify();
    final copyWith = config.copyWith();
    final equality = config.equality();
    final fromJson = config.fromJson();
    final toJson = config.toJson();
    final detectDate = config.detectDate();

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

    // map of keyName => propertyName
    final prop = getPropName(json);
    final props = prop.values.toList();

    json.forEach((key, value) {
      code.writeln('    ${isRequired ? 'required ' : ''}this.${prop[key]},');
    });
    code.write('  });\n');

    // map of keyName => Type
    final types = <String, String>{};

    final classList = <String>[];

    // fields
    final fieldBuffer = StringBuffer();
    json.forEach((key, value) {
      var type = _generateField(
        key: key,
        value: value,
        classList: classList,
        importList: importList,
      );
      if (detectDate && isDate(value)) type = 'DateTime';
      types[key] = type;
      fieldBuffer.writeln(
        '  ${isMutable ? '' : 'final '}$type${isNullable ? '?' : ''} ${prop[key]};',
      );
    });

    final keys = json.keys.toList();

    // fromJson
    if (fromJson) {
      code.writeln(
        '\n  factory $className.fromJson(Map<String, dynamic> json) => $className(\n'
        '    ${json.entries.map((e) {
          final k = e.key;

          // for date
          if (detectDate && isDate(e.value)) {
            final parser = "DateTime.parse(json['$k'] as String)";
            return "${prop[k]}: ${isNullable ? "json['$k'] != null ? $parser : null" : parser},";
          }

          return "${prop[k]}: json['$k'] as ${types[k]}${isNullable ? '?' : ''},";
        }).join('\n    ')}\n'
        '  );',
      );
    }

    code
      ..writeln()
      ..write(fieldBuffer.toString());

    // toString
    if (toString) {
      code
        ..writeln('\n  @override')
        ..writeln(
          '  String toString() =>\n'
          "      '$className('\n"
          "      ${props.map((e) => "' $e: \$$e").join(",'\n      ")}'\n"
          "      ')';",
        );
    }

    // copyWith
    if (copyWith) {
      code.writeln(
        '\n  $className copyWith({\n'
        '    ${keys.map((e) => '${types[e]}? ${prop[e]},').join('\n    ')}\n'
        '  }) => $className(\n'
        '    ${props.map((e) => '$e: $e ?? this.$e,').join('\n    ')}\n'
        '  );',
      );
    }

    // toJson
    if (toJson) {
      code.writeln(
        '\n  Map<String, dynamic> toJson() => {\n'
        '    ${json.entries.map((e) {
          final k = e.key;

          // for date
          if (detectDate && isDate(e.value)) {
            return "'$k': ${prop[k]}${isNullable ? '?' : ''}.toIso8601String(),";
          }

          return "'$k': ${prop[k]},";
        }).join("\n    ")}\n'
        '  };',
      );
    }

    // equality and hashCode
    if (equality) {
      code.writeln(
        '\n  @override\n'
        '  bool operator ==(Object other) {\n'
        '    if (identical(this, other)) return true;\n'
        '    return other is $className &&\n'
        '        ${props.map((e) => 'other.$e == $e').join(' &&\n        ')};\n'
        '  }\n\n'
        '  @override\n'
        '  int get hashCode =>\n'
        '      ${props.map((e) => '$e.hashCode').join(' ^\n      ')};',
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
      case int() || double() || bool() || String():
        type = value.runtimeType.toString();
      case Json():
        type = getUniqName(key.toPascalCase());
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

  late final Toggle<bool> mutable = toggle(
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

  late final Toggle<bool> required = toggle(
    'Required',
    initial: true,
    onChange: (value) {
      if (!value) nullable.value = true;
    },
  );

  late final Toggle<bool> nullable = toggle(
    'Nullable',
    onChange: (value) {
      if (!value) required.value = true;
    },
  );
  late final Toggle<bool> stringify = toggle('toString');

  late final Toggle<bool> copyWith = toggle('copyWith');

  late final Toggle<bool> equality = toggle(
    'Equality',
    onChange: (value) {
      if (value) mutable.value = false;
    },
  );

  late final Toggle<bool> fromJson = toggle('fromJson');

  late final Toggle<bool> toJson = toggle('toJson');

  late final Toggle<bool> detectDate = toggle('Detect Date');

  @override
  Set<Toggle> get toggles => {
    mutable,
    required,
    nullable,
    stringify,
    copyWith,
    equality,
    fromJson,
    toJson,
    detectDate,
  };
}
