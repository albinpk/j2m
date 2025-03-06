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
  dynamic _data;

  /// The JSON data to convert.
  dynamic get data => _data;

  void setJson(dynamic data) {
    assert(data is Map || data is List, 'Invalid data type');
    _data = data;
  }

  /// Converts JSON data to code blocks.
  void convert();

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
