part of 'base.dart';

/// Toggle option for a converter.
class Toggle {
  const Toggle._(this.name, this._converter, {bool initial = false})
    : _initial = initial;

  /// Display name.
  final String name;

  final ConverterBase _converter;
  final bool _initial;

  /// Get the current value.
  bool call() => value;

  /// Get the current value.
  bool get value => _converter._getToggleValue(name) ?? _initial;

  /// Set the value.
  set value(bool value) => _converter._setToggleValue(name, value);

  /// Toggle the value.
  void toggle() => _converter._setToggleValue(name, !call());
}
