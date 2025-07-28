import 'package:change_case/change_case.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';

import '../../converter/base.dart';
import '../../types.dart';

/// Freezed converter for Dart language.
final class DartFluConverter extends ConverterBase<DartFluConfig> {
  @override
  late final DartFluConfig config = DartFluConfig(this);

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
    newClass(className);

    final jsonKey = config.jsonKey();
    final allDateTime = config.detectDate();
    final allNullable = config.nullable();

    final fileName = modelName.toSnakeCase();

    importList.addAll({
      Line("part '$fileName.flu.dart';"),
    });

    final lines = <Line>[
      const Line('// @flu'),
      Line('abstract class _$className {'),
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
      final checkBoxes = <CheckBoxOption>[
        CheckBoxOption(
          label: 'Nullable',
          value: nullable,
          onChange: (v) => setLineConfig(id, {'nullable': v}),
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
            value: useJsonKey ?? key != propName,
            onChange: (v) => setLineConfig(id, {'useJsonKey': v}),
          ),
        );
      }

      final jsonKeyAnnotation = Line('  // @flu key="$key"');

      lines.addAll([
        ?switch (useJsonKey) {
          true => jsonKeyAnnotation,
          null when key != propName => jsonKeyAnnotation,
          _ => null,
        },
        Line(
          '  $type${nullable ? '?' : ''} get $propName;',
          option: haveConfig || checkBoxes.isNotEmpty
              ? Option(
                  checkBoxes: checkBoxes,
                  reset: haveConfig ? () => deleteLineConfig(id) : null,
                )
              : null,
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
        final generic = value.isEmpty
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

final class DartFluConfig extends ConfigBase {
  DartFluConfig(super.converter);

  late final Toggle<bool?> jsonKey = toggle('JsonKey', initial: null);

  late final Toggle<bool> detectDate = toggle('Detect Date', initial: true);

  late final Toggle<bool> nullable = toggle('Nullable');

  @override
  Set<Toggle> get toggles => {
    nullable,
    jsonKey,
    detectDate,
  };
}
