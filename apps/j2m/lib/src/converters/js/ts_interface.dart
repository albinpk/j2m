import 'package:change_case/change_case.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/typescript.dart';

import '../../converter/base.dart';
import '../../types.dart';

/// Interface converter for TypeScript language.
final class TSInterfaceConverter extends ConverterBase<TSInterfaceConfig> {
  @override
  late final TSInterfaceConfig config = TSInterfaceConfig(this);

  @override
  final CodeController controller = CodeController(language: typescript);

  @override
  String propCasing(String prop) => prop.toCamelCase();

  @override
  String classCasing(String className) => className.toPascalCase();

  @override
  String generateCode() {
    return _generateInterface(json: json, name: modelName);
  }

  @override
  List<Line> generateLines() {
    return generateCode().split('\n').map(Line.new).toList();
  }

  String _generateInterface({required Json json, required String name}) {
    if (json.isEmpty) return '';

    // toggles
    final nullable = config.nullable();

    // map of keyName => propertyName
    final prop = getPropName(json);

    final interfaceList = <String>[]; // sub models

    // interface start
    final code = StringBuffer('interface $name {\n');
    json.forEach((key, value) {
      final type = _generateField(
        key: key,
        value: value,
        interfaceList: interfaceList,
      );
      code.writeln('  ${prop[key]}${nullable ? '?' : ''}: $type;');
    });
    code.writeln('}'); // interface end

    // sub models
    for (final i in interfaceList) {
      code
        ..write('\n')
        ..write(i);
    }
    return code.toString();
  }

  /// Generate a field and return its type.
  String _generateField({
    required String key,
    required dynamic value,
    required List<String> interfaceList,
  }) {
    final String type;
    switch (value) {
      case int() || double():
        type = 'number';
      case String():
        type = 'string';
      case bool():
        type = 'boolean';
      case Json():
        type = key.toPascalCase();
        interfaceList.add(_generateInterface(json: value, name: type));
      case List():
        final generic =
            value.isEmpty
                ? 'undefined'
                : _generateField(
                  key: key,
                  value: value[0],
                  interfaceList: interfaceList,
                );
        type = '$generic[]';
      default:
        type = 'undefined';
    }
    return type;
  }
}

final class TSInterfaceConfig extends ConfigBase {
  TSInterfaceConfig(super.converter);

  late final Toggle<bool> nullable = toggle('Nullable');

  @override
  Set<Toggle> get toggles => {nullable};
}
