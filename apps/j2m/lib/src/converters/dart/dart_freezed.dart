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
  void convert() {
    final importList = <String>{}; // mutable
    final code = _generateClass(
      json: json,
      className: modelName,
      importList: importList,
    );
    controller.fullText =
        importList.isNotEmpty ? '${importList.join('\n')}\n\n$code' : code;
  }

  String _generateClass({
    required Json json,
    required String className,
    required Set<String> importList,
  }) {
    if (json.isEmpty) return '';

    final mutable = config.mutable();
    final isRequired = config.required();
    final isNullable = config.nullable();
    final toString = config.stringify();
    final copyWith = config.copyWith();
    final equality = config.equality();
    final fromJson = config.fromJson();
    final toJson = config.toJson();

    final fileName = modelName.toSnakeCase();

    // create @Freezed annotation
    final annotation = () {
      final fields = <String>{};
      final unfreezed = {
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

    importList.addAll([
      "import 'package:freezed_annotation/freezed_annotation.dart';",
      "\npart '$fileName.freezed.dart';",
      if (fromJson) "part '$fileName.g.dart';",
    ]);

    final classList = <String>[];

    final code = StringBuffer(
      '$annotation\n'
      'abstract class $className with _\$$className {\n'
      '  ${mutable ? '' : 'const '}factory $className({\n',
    );

    // fields
    json.forEach((key, value) {
      final type = _generateField(
        key: key,
        value: value,
        classList: classList,
        importList: importList,
      );
      code.writeln(
        '    ${isRequired ? 'required ' : ''}$type${isNullable ? '?' : ''} ${propCasing(key)},',
      );
    });
    code.writeln('  }) = _$className;'); // constructor end

    // fromJson
    if (fromJson) {
      code.writeln(
        '\n  factory $className.fromJson(Map<String, Object?> json) => '
        '_\$${className}FromJson(json);',
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
  };
}
