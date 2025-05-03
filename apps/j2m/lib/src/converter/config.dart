part of 'base.dart';

/// Base class for language configurations.
abstract class ConfigBase {
  const ConfigBase(this._converter);

  final ConverterBase _converter;

  /// The list of toggles buttons in the UI.
  @protected
  abstract final Set<Toggle> toggles;

  /// Create a toggle.
  @protected
  Toggle<T> toggle<T extends bool?>(
    String name, {
    bool? initial = false,
    ValueChanged<T>? onChange,
  }) => Toggle<T>._(name, _converter, initial: initial, onChange: onChange);
}
