class AppConfig {
  AppConfig._();

  static const bool isDemoBuild = true;

  static String get buildLabel => isDemoBuild ? 'DEMO' : '';

  static bool get allFeaturesUnlocked => isDemoBuild;
}