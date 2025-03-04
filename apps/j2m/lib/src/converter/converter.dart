import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import 'config.dart';

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

  void setData(dynamic data) {
    assert(data is Map || data is List, 'Invalid data type');
    _data = data;
  }

  /// Converts JSON data to code blocks.
  void convert();

  @mustCallSuper
  void dispose() {
    controller.dispose();
  }

  late final _toggleData = {for (final key in config.toggles) key: false};

  /// Get the current value of a toggle.
  bool getToggleValue(String key) => _toggleData[key]!;

  /// Get all toggles and their values.
  Set<({VoidCallback change, String label, bool value})> get toggles => {
    for (final toggle in config.toggles)
      (
        label: toggle,
        value: getToggleValue(toggle),
        change: () => _toggleData[toggle] = !getToggleValue(toggle),
      ),
  };
}
