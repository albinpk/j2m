part of 'base.dart';

/// Base class for all converters.
abstract class ConverterBase {
  ConverterBase();

  /// Language configuration for the converter.
  @protected
  abstract final ConfigBase config;

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
  final _toggleData = <String, bool>{};

  /// Get the current value of a toggle.
  bool? _getToggleValue(String key) => _toggleData[key];

  /// Set the value of a toggle.
  void _setToggleValue(String key, bool value) => _toggleData[key] = value;
}
