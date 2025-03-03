import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  /// ThemeData
  ThemeData get theme => Theme.of(this);

  /// ColorScheme
  ColorScheme get cs => theme.colorScheme;

  /// TextTheme
  TextTheme get tt => theme.textTheme;
}
