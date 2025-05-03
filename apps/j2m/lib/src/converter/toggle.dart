part of 'base.dart';

/// Toggle option for a converter.
class Toggle<T extends bool?> {
  const Toggle._(
    this.name,
    this._converter, {
    bool? initial = false,
    ValueChanged<T>? onChange,
  }) : _initial = initial as T,
       _onChange = onChange;

  /// Display name.
  final String name;

  final ConverterBase _converter;
  final T _initial;
  final ValueChanged<T>? _onChange;

  /// Get the current value.
  T call() => value;

  /// Get the current value.
  T get value => (_converter._getToggleValue(name) as T?) ?? _initial;

  /// Set the value.
  set value(T value) {
    _onChange?.call(value);
    _converter._setToggleValue(name, value);
  }

  /// Toggle the value.
  void toggle() {
    if (T == bool) {
      value = !value! as T;
    } else {
      // tristate
      value =
          switch (value) {
                true => false,
                false => null,
                null => true,
              }
              as T;
    }
  }
}
