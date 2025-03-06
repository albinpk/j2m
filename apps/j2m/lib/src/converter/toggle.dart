part of 'base.dart';

/// Toggle option for a converter.
class Toggle {
  const Toggle._(
    this.name,
    this._converter, {
    bool initial = false,
    ValueChanged<bool>? onChange,
  }) : _initial = initial,
       _onChange = onChange;

  /// Display name.
  final String name;

  final ConverterBase _converter;
  final bool _initial;
  final ValueChanged<bool>? _onChange;

  /// Get the current value.
  bool call() => value;

  /// Get the current value.
  bool get value => _converter._getToggleValue(name) ?? _initial;

  /// Set the value.
  set value(bool value) {
    _onChange?.call(value);
    _converter._setToggleValue(name, value);
  }

  /// Toggle the value.
  void toggle() => value = !value;
}
