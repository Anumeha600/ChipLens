/// Central environment configuration.
/// Override at build time: flutter build apk --dart-define=PROD=true
class AppConfig {
  AppConfig._();

  // Fallback LAN IP — used only if auto-discovery fails on startup.
  // Update this if discovery is consistently failing on a new network.
  static const String _devBase  = 'http://10.117.35.181:3000/api/v1';
  static const String _prodBase = 'https://api.chiplens.com/api/v1';

  static const bool _production =
      bool.fromEnvironment('PROD', defaultValue: false);

  // Set at startup by BackendDiscovery when the backend is found on the LAN.
  // Falls back to _devBase until discovery succeeds.
  static String _resolvedBase = _devBase;
  static void setResolvedBase(String base) => _resolvedBase = base;

  static String get apiBase => _production ? _prodBase : _resolvedBase;

  static const String appName    = 'ChipLens';
  static const String appTagline = 'AI-Powered RTL Analysis Workspace';
  static const String version    = '1.0.0';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 45);
  static const Duration sendTimeout    = Duration(seconds: 15);

  // Allowed Verilog file extensions (lowercase, with dot)
  static const Set<String> allowedExtensions = {'.v', '.sv', '.vh', '.svh', '.txt'};

  // Reference/schematic file extensions (images + PDFs — displayed as-is, not parsed)
  static const Set<String> referenceExtensions = {'.jpg', '.jpeg', '.png', '.pdf'};
}
