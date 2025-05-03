part of 'base.dart';

/// Base class for all converters.
abstract class ConverterBase<T extends ConfigBase> {
  ConverterBase();

  /// Language configuration for the converter.
  @protected
  abstract final T config;

  /// Code controller for the output view.
  abstract final CodeController controller;

  /// JSON data to convert.
  Json? _json;

  /// Set JSON data to convert.
  // ignore: use_setters_to_change_properties
  void setJson(Json json) => _json = json;

  /// JSON data to convert.
  Json get json {
    assert(_json != null, 'JSON data is not set');
    return _json!;
  }

  /// Set JSON data from a string.
  void setJsonFromString(String text) {
    final data = jsonDecode(text);
    setJsonFromDecoded(data);
  }

  /// Set JSON data from decoded data.
  void setJsonFromDecoded(dynamic data) {
    if (data case final Json json || [final Json json, ...]) {
      setJson(json);
    } else {
      throw const FormatException('Invalid JSON data');
    }
  }

  /// Default name of the root model class if not set.
  static const defaultModelName = 'User';

  /// Name of the root model class.
  String _modelName = defaultModelName;

  /// Name of the root model class.
  String get modelName => _modelName;

  /// Name of the root model class.
  set modelName(String value) {
    final name = value.trim();
    _modelName = classCasing(name.isEmpty ? defaultModelName : name);
  }

  /// Converts JSON data to code blocks.
  @nonVirtual
  void convert() {
    _classNameList.clear();
    final lines = generateLines();
    controller.fullText = lines.join('\n');
    _lines = lines.length;
    _lineOptions = {
      for (final (i, Line(:option)) in lines.indexed)
        if (option != null) i: option,
    };
  }

  /// Storing class names to avoid duplicates.
  final _classNameList = <String>[];

  /// Add a new class name to the list.
  void newClass(String className) => _classNameList.add(className);

  /// Generate a uniq name for class if already
  /// exists by adding a number at the end.
  String getUniqName(String className) {
    var name = className;
    var i = 1;
    while (_classNameList.contains(name)) {
      name = '$className${i++}';
    }
    return name;
  }

  /// Total number of lines.
  int get lines => _lines;
  int _lines = 0;

  /// Options for each line.
  Map<int, Option> get lineOptions => _lineOptions;
  Map<int, Option> _lineOptions = {};

  // TODO(albin): remove
  /// Generate code from JSON data.
  @Deprecated('Use "generateLines" instead')
  @protected
  String generateCode() => '';

  /// Generate code blocks from JSON data.
  @protected
  List<Line> generateLines();

  /// Casing for property names.
  String propCasing(String prop) => prop;

  /// Casing for class names.
  String classCasing(String className) => className;

  /// Get a map of property names and their casing.
  Map<String, String> getPropName(Json json) =>
      json.map((key, value) => MapEntry(key, propCasing(key)));

  /// Check if a [value] is a date.
  bool isDate(dynamic value) => DateTime.tryParse('$value') != null;

  @mustCallSuper
  void dispose() {
    controller.dispose();
  }

  /// Get all toggles for the converter.
  Set<Toggle> get toggles => config.toggles;

  /// Data for toggles.
  final Map<String, bool?> _toggleData = {};

  /// Get the current value of a toggle.
  bool? _getToggleValue(String key) => _toggleData[key];

  bool _validating = false;

  /// Set the value of a toggle.
  void _setToggleValue(String key, bool? value) {
    if (!_validating) {
      _validating = true;
      _validating = false;
    }
    _toggleData[key] = value;
  }

  final _lineConfig = <String, Map<String, bool>>{};

  /// Set the config for a line.
  void setLineConfig(String key, Map<String, bool> config) {
    _lineConfig[key] = {...?_lineConfig[key], ...config};
  }

  /// Get the config for a line.
  Map<String, bool>? getLineConfig(String key) => _lineConfig[key];

  /// Check if a line has config.
  bool haveLineConfig(String key) => _lineConfig.containsKey(key);

  /// Delete the config for a line.
  void deleteLineConfig(String key) => _lineConfig.remove(key);
}

/// Line of code.
@immutable
class Line {
  const Line(this.text, {this.option});

  /// Actual text content of the line.
  final String text;

  /// Options for the line.
  final Option? option;

  /// Empty line.
  static const empty = Line('');

  @override
  String toString() => text;

  @override
  bool operator ==(covariant Line other) {
    if (identical(this, other)) return true;
    return other.text == text && other.option == option;
  }

  @override
  int get hashCode => text.hashCode ^ option.hashCode;
}

/// Options for a line.
@immutable
class Option {
  const Option({required this.reset, required this.checkBoxes});

  /// Callback to reset line options.
  final VoidCallback? reset;

  /// Checkbox options.
  final List<CheckBoxOption> checkBoxes;
}

/// Checkbox option for a line.
@immutable
class CheckBoxOption {
  const CheckBoxOption({
    required this.label,
    required this.value,
    required this.onChange,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool> onChange;
}
