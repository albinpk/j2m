/// Base class for language configurations.
abstract class ConfigBase {
  const ConfigBase();

  /// The list of toggles buttons in the UI.
  abstract final Set<String> toggles;
}
