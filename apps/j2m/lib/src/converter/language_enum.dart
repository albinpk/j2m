/// All supported languages
enum Language {
  dart('Dart'),
  javascript('JavaScript');

  const Language(this.label);

  /// Display name.
  final String label;
}
