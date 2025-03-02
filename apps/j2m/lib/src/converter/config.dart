/// Base class for language configurations.
abstract class ConfigBase {
  const ConfigBase();

  abstract final Set<String> toggles;
}
