import '../converters/dart/dart_classic.dart';
import '../converters/dart/dart_flu.dart';
import '../converters/dart/dart_freezed.dart';
import '../converters/js/ts_interface.dart';
import '../converters/kotlin/kotlin_data_class.dart';
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

  /// All registered variants.
  static const Map<Language, Set<Variant>> _variantsMap = {
    Language.dart: {
      Variant('Classic', DartClassicConverter.new),
      Variant('Freezed', DartFreezedConverter.new),
      Variant('Flu', DartFluConverter.new),
    },
    Language.javascript: {Variant('Interface', TSInterfaceConverter.new)},
    Language.kotlin: {Variant('Data Class', KotlinDataClassConverter.new)},
  };
}
