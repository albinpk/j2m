import 'package:change_case/change_case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';

import '../../converter/base.dart';
import '../../types.dart';

/// Freezed converter for Dart language.
final class DartFreezedConverter extends ConverterBase<DartFreezedConfig> {
  @override
  late final DartFreezedConfig config = DartFreezedConfig(this);

  @override
  final CodeController controller = CodeController(language: dart);

  @override
  String propCasing(String prop) => prop.toCamelCase();

  @override
  String classCasing(String className) => className.toPascalCase();

  // @override
  // void convert() {
  //   final importList = <String>{}; // mutable
  //   final code = _generateClass(
  //     json: json,
  //     className: modelName,
  //     importList: importList,
  //   );
  //   controller.fullText =
  //       importList.isNotEmpty ? '${importList.join('\n')}\n\n$code' : code;
  // }

  @override
  String generateCode() {
    final importList = <Line>{}; // mutable
    final code = _generateClass(
      json: json,
      className: modelName,
      parent: modelName,
      importList: importList,
    );
    return importList.isNotEmpty
        ? '${importList.join('\n')}\n\n$code'
        : code.toString();
  }

  @override
  List<Line> generateLines() {
    final importList = <Line>{}; // mutable
    final code = _generateClass(
      json: json,
      className: modelName,
      parent: modelName,
      importList: importList,
    );
    // return importList.isNotEmpty ? '${importList.join('\n')}\n\n$code' : code;
    return [...importList, Line.empty, ...code];
  }

  List<Line> _generateClass({
    required Json json,
    required String className,
    required String parent,
    required Set<Line> importList,
  }) {
    if (json.isEmpty) return [];

    final mutable = config.mutable();
    final isRequired = config.required();
    final isNullable = config.nullable();
    final toString = config.stringify();
    final copyWith = config.copyWith();
    final equality = config.equality();
    final fromJson = config.fromJson();
    final toJson = config.toJson();
    final jsonKey = config.jsonKey();
    final detectDate = config.detectDate();

    final fileName = modelName.toSnakeCase();

    // create @Freezed annotation
    final annotation = () {
      final fields = <String>{};
      const unfreezed = {
        'equal: false',
        'addImplicitFinal: false',
        'makeCollectionsUnmodifiable: false',
      };
      if (mutable) fields.addAll(unfreezed);
      if (!copyWith) fields.add('copyWith: false');
      if (!equality) fields.add('equal: false');
      if (!toString) fields.add('toStringOverride: false');
      if (toJson != fromJson) fields.add('toJson: $toJson');
      if (fields.isEmpty) return '@freezed';
      if (fields.length == 1) return '@Freezed(${fields.first})'; // single line
      if (setEquals(fields, unfreezed)) return '@unfreezed';
      return '@Freezed(\n  ${fields.join(',\n  ')},\n)'; // multi line
    }();

    importList.addAll({
      const Line(
        "import 'package:freezed_annotation/freezed_annotation.dart';",
      ),
      Line.empty,
      Line("part '$fileName.freezed.dart';"),
      if (fromJson) Line("part '$fileName.g.dart';"),
    });

    final lines = <Line>[
      Line(annotation),
      Line('abstract class $className with _\$$className {'),
      Line('  ${mutable ? '' : 'const '}factory $className({'),
    ];

    // final code = StringBuffer();

    final classList = <List<Line>>[];

    // fields
    json.forEach((key, value) {
      var type = _generateField(
        key: key,
        parent: '$parent.$key',
        value: value,
        classList: classList,
        importList: importList,
      );

      final context = '$parent.$key';

      Option? option;
      if (isDate(value)) {
        option = Option(
          checkBoxes: [
            CheckBoxOption(
              label: 'Use DateTime',
              value: detectDate,
              onChange: (value) {
                print('$context: $value');
              },
            ),
          ],
        );
        if (detectDate) type = 'DateTime';
      }
      // code.writeln(
      //   '    ${jsonKey ? '@JsonKey(name: "$key") ' : ''}${isRequired ? 'required ' : ''}$type${isNullable ? '?' : ''} ${propCasing(key)},',
      // );
      lines.add(
        Line(
          '    ${jsonKey ? '@JsonKey(name: "$key") ' : ''}${isRequired ? 'required ' : ''}$type${isNullable ? '?' : ''} ${propCasing(key)},',
          option: option,
        ),
      );
    });
    // code.writeln('  }) = _$className;'); // constructor end
    lines.add(Line('  }) = _$className;'));

    // fromJson
    if (fromJson) {
      // code.writeln(
      //   '\n  factory $className.fromJson(Map<String, Object?> json) => '
      //   '_\$${className}FromJson(json);',
      // );
      lines.addAll([
        Line.empty,
        Line(
          '  factory $className.fromJson(Map<String, Object?> json) => '
          '_\$${className}FromJson(json);',
        ),
      ]);
    }

    // code.writeln('}'); // class end
    lines.add(const Line('}'));

    // sub models
    for (final classDef in classList) {
      // code
      //   ..write('\n')
      //   ..write(classDef);
      lines.addAll([Line.empty, ...classDef]);
    }
    // return code.toString();
    return lines;
  }

  /// Generate a field and return its type.
  String _generateField({
    required String key,
    required String parent,
    required dynamic value,
    required List<List<Line>> classList,
    // required List<Line> lines,
    required Set<Line> importList,
  }) {
    final String type;
    switch (value) {
      case int() || double() || bool() || String():
        type = value.runtimeType.toString();
      case Json():
        type = key.toPascalCase();
        classList.add(
          _generateClass(
            json: value,
            className: type,
            importList: importList,
            parent: parent,
          ),
        );
      case List():
        final generic =
            value.isEmpty
                ? 'dynamic'
                : _generateField(
                  key: key,
                  parent: parent,
                  value: value[0],
                  // lines: lines,
                  classList: classList,
                  importList: importList,
                );
        type = 'List<$generic>';
      default:
        type = 'dynamic';
    }
    return type;
  }
}

final class DartFreezedConfig extends ConfigBase {
  DartFreezedConfig(super.converter);

  late final Toggle mutable = toggle(
    'Mutable',
    onChange: (value) => equality.value = !value,
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
  late final Toggle stringify = toggle('toString', initial: true);

  late final Toggle copyWith = toggle('copyWith', initial: true);

  late final Toggle equality = toggle('Equality', initial: true);

  late final Toggle fromJson = toggle('fromJson', initial: true);

  late final Toggle toJson = toggle('toJson', initial: true);

  // TODO(albin): automatic key (if not camelCase)
  late final Toggle jsonKey = toggle('JsonKey');

  late final Toggle detectDate = toggle('Detect Date');

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
    jsonKey,
    detectDate,
  };
}
