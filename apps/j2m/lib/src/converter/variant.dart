import '../converters/dart/dart_classic.dart';
import 'base.dart';
import 'language_enum.dart';

/// Converter variant for a language.
class Variant {
  const Variant(this.name, this.converter);

  /// Variant name.
  final String name;

  /// Converter creator.
  final ConverterBase Function() converter;

  /// Get variants for [language].
  static Set<Variant> ofLanguage(Language language) => _variantsMap[language]!;

  // extracted for initial value
  static const Variant dartClassic = Variant(
    'Classic',
    DartClassicConverter.new,
  );

  /// All registered variants.
  static const Map<Language, Set<Variant>> _variantsMap = {
    Language.dart: {dartClassic},
  };
}
