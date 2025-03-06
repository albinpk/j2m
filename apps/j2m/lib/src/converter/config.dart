part of 'base.dart';

/// Base class for language configurations.
abstract class ConfigBase {
  const ConfigBase(this._converter);

  final ConverterBase _converter;

  /// The list of toggles buttons in the UI.
  @protected
  abstract final Set<Toggle> toggles;

  @protected
  Toggle toggle(String name, {bool initial = false}) =>
      Toggle._(name, _converter, initial: initial);
}
