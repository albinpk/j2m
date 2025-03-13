/// All supported languages
enum Language {
  dart('Dart'),
  javascript('JavaScript'),
  kotlin('Kotlin');

  const Language(this.label);

  /// Display name.
  final String label;
}
