enum AppMode {
  admin,
  host,
  display,
}

class AppModeConfig {
  static AppMode currentMode = AppMode.admin;

  static bool get isAdminMode => currentMode == AppMode.admin;
  static bool get isHostMode => currentMode == AppMode.host;
  static bool get isDisplayMode => currentMode == AppMode.display;

  static void setMode(AppMode mode) {
    currentMode = mode;
  }
}

