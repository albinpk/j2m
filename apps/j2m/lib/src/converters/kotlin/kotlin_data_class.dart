import 'package:change_case/change_case.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/kotlin.dart';

import '../../converter/base.dart';
import '../../types.dart';

/// Data class converter for Kotlin language.
final class KotlinDataClassConverter
    extends ConverterBase<KotlinDataClassConfig> {
  @override
  late final KotlinDataClassConfig config = KotlinDataClassConfig(this);

  @override
  final CodeController controller = CodeController(language: kotlin);

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

    final nullable = config.nullable();
    final serializedName = config.serializedName();

    if (serializedName) {
      importList.add('import com.google.gson.annotations.SerializedName');
    }

    final classList = <String>[];

    // class start
    final code = StringBuffer('data class $className (\n');

    // fields
    json.forEach((key, value) {
      final type = _generateField(
        key: key,
        value: value,
        classList: classList,
        importList: importList,
      );
      code.writeln(
        '  ${serializedName ? '@SerializedName("$key") ' : ''}val ${propCasing(key)}: $type${nullable ? '?' : ''},',
      );
    });

    code.writeln(')'); // class end

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
        type = 'Int';
      case double():
        type = 'Double';
      case bool():
        type = 'Boolean';
      case String():
        type = 'String';
      case Json():
        type = key.toPascalCase();
        classList.add(
          _generateClass(json: value, className: type, importList: importList),
        );
      case List(:final isEmpty):
        final generic =
            isEmpty
                ? 'Any'
                : _generateField(
                  key: key,
                  value: value[0],
                  classList: classList,
                  importList: importList,
                );
        type = 'List<$generic>';
      default:
        type = 'Any';
    }
    return type;
  }
}

final class KotlinDataClassConfig extends ConfigBase {
  KotlinDataClassConfig(super.converter);

  late final Toggle nullable = toggle('Nullable');
  late final Toggle serializedName = toggle('SerializedName');

  @override
  Set<Toggle> get toggles => {nullable, serializedName};
}
