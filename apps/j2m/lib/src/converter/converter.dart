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
  @Deprecated('Use "_json" instead')
  dynamic _data;

  /// The JSON data to convert.
  @Deprecated('Use "json" instead')
  dynamic get data => _data;

  @Deprecated('Use "" instead')
  void setJsonOld(dynamic data) {
    assert(data is Map || data is List, 'Invalid data type');
    _data = data;
  }

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
  static const defaultModelName = 'Model';

  /// Name of the root model class.
  String? _modelName;

  /// Name of the root model class.
  String get modelName {
    if (_modelName == null) modelName = defaultModelName;
    return _modelName!;
  }

  /// Name of the root model class.
  set modelName(String value) {
    final name = value.trim();
    _modelName = classCasing(name.isEmpty ? defaultModelName : name);
  }

  /// Converts JSON data to code blocks.
  void convert();

  /// Casing for property names.
  String propCasing(String prop) => prop;

  /// Casing for class names.
  String classCasing(String className) => className;

  /// Get a map of property names and their casing.
  Map<String, String> getPropName(Json json) =>
      json.map((key, value) => MapEntry(key, propCasing(key)));

  @mustCallSuper
  void dispose() {
    controller.dispose();
  }

  /// Get all toggles for the converter.
  Set<Toggle> get toggles => config.toggles;

  /// Data for toggles.
  final Map<String, bool> _toggleData = {};

  /// Get the current value of a toggle.
  bool? _getToggleValue(String key) => _toggleData[key];

  bool _validating = false;

  /// Set the value of a toggle.
  void _setToggleValue(String key, bool value) {
    if (!_validating) {
      _validating = true;
      onToggleChange(key, value);
      _validating = false;
    }
    _toggleData[key] = value;
  }

  /// Called when a toggle value is changed.
  @Deprecated('Use toggle.onChange instead')
  @protected
  // ignore: avoid_positional_boolean_parameters
  void onToggleChange(String key, bool value) {}
}
