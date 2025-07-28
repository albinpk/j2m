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

  @override
  List<Line> generateLines() {
    final importList = <Line>{}; // mutable
    final code = _generateClass(
      json: json,
      className: modelName,
      parent: modelName,
      importList: importList,
    );
    return [...importList, Line.empty, ...code];
  }

  List<Line> _generateClass({
    required Json json,
    required String className,
    required String parent,
    required Set<Line> importList,
  }) {
    if (json.isEmpty) return [];
    newClass(className);

    final allMutable = config.mutable();
    final allRequired = config.required();
    final allNullable = config.nullable();
    final toString = config.stringify();
    final copyWith = config.copyWith();
    final equality = config.equality();
    final fromJson = config.fromJson();
    final toJson = config.toJson();
    final jsonKey = config.jsonKey();
    final allDateTime = config.detectDate();

    final fileName = modelName.toSnakeCase();

    // create @Freezed annotation
    final annotation = () {
      final fields = <String>{};
      const unfreezed = {
        'equal: false',
        'addImplicitFinal: false',
        'makeCollectionsUnmodifiable: false',
      };
      if (allMutable) fields.addAll(unfreezed);
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
      Line('  ${allMutable ? '' : 'const '}factory $className({'),
    ];

    final classList = <List<Line>>[];

    // fields
    for (final MapEntry(:key, :value) in json.entries) {
      final id = '$parent.$key';
      final propName = propCasing(key);
      final haveConfig = haveLineConfig(id);
      final lineConfig = getLineConfig(id) ?? {};

      var type = _generateField(
        key: key,
        parent: id,
        value: value,
        classList: classList,
        importList: importList,
      );

      final nullable = lineConfig['nullable'] ?? allNullable;
      final immutable = lineConfig['immutable'] ?? false;
      final checkBoxes = <CheckBoxOption>[
        if (allRequired)
          CheckBoxOption(
            label: 'Nullable',
            value: nullable,
            onChange: (v) => setLineConfig(id, {'nullable': v}),
          ),
        if (allMutable)
          CheckBoxOption(
            label: 'Immutable',
            value: immutable,
            onChange: (v) => setLineConfig(id, {'immutable': v}),
          ),
      ];

      if (isDate(value)) {
        final dateTime = lineConfig['dateTime'] ?? allDateTime;
        checkBoxes.add(
          CheckBoxOption(
            label: 'Use DateTime',
            value: dateTime,
            onChange: (v) => setLineConfig(id, {'dateTime': v}),
          ),
        );
        if (dateTime) type = 'DateTime';
      }

      final useJsonKey = lineConfig['useJsonKey'] ?? jsonKey;
      if (key != propName) {
        checkBoxes.add(
          CheckBoxOption(
            label: 'JsonKey',
            value: useJsonKey ?? key == propName,
            onChange: (v) => setLineConfig(id, {'useJsonKey': v}),
          ),
        );
      }

      lines.add(
        Line(
          '    ${switch (useJsonKey) {
            true => "@JsonKey(name: '$key') ",
            false => '',
            null => key == propName ? '' : "@JsonKey(name: '$key') ",
          }}'
          '${allRequired ? 'required ' : ''}'
          '${immutable ? 'final ' : ''}'
          '$type${nullable ? '?' : ''} '
          '$propName,',
          option:
              haveConfig || checkBoxes.isNotEmpty
                  ? Option(
                    checkBoxes: checkBoxes,
                    reset: haveConfig ? () => deleteLineConfig(id) : null,
                  )
                  : null,
        ),
      );
    }

    lines.add(Line('  }) = _$className;')); // constructor end

    // fromJson
    if (fromJson) {
      lines.addAll([
        Line.empty,
        Line(
          '  factory $className.fromJson(Map<String, Object?> json) => '
          '_\$${className}FromJson(json);',
        ),
      ]);
    }

    lines.add(const Line('}')); // class end

    // sub models
    for (final classDef in classList) {
      lines.addAll([Line.empty, ...classDef]);
    }
    return lines;
  }

  /// Generate a field and return its type.
  String _generateField({
    required String key,
    required dynamic value,
    required String parent,
    required List<List<Line>> classList,
    required Set<Line> importList,
  }) {
    final String type;
    switch (value) {
      case int() || double() || bool() || String():
        type = value.runtimeType.toString();
      case Json():
        type = getUniqName(key.toPascalCase());
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
                  value: value[0],
                  parent: parent,
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

  late final Toggle<bool> mutable = toggle(
    'Mutable',
    onChange: (value) => equality.value = !value,
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
  late final Toggle<bool> stringify = toggle('toString', initial: true);

  late final Toggle<bool> copyWith = toggle('copyWith', initial: true);

  late final Toggle<bool> equality = toggle('Equality', initial: true);

  late final Toggle<bool> fromJson = toggle('fromJson', initial: true);

  late final Toggle<bool> toJson = toggle('toJson', initial: true);

  late final Toggle<bool?> jsonKey = toggle('JsonKey', initial: null);

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
    jsonKey,
    detectDate,
  };
}
