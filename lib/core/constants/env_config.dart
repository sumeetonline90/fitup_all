import 'package:envied/envied.dart';

part 'env_config.g.dart';

/// API keys loaded from `.env` at build time (never commit `.env`).
@Envied(path: '.env')
abstract class EnvConfig {
  @EnviedField(varName: 'GEMINI_API_KEY', obfuscate: true)
  static final String geminiApiKey = _EnvConfig.geminiApiKey;

  @EnviedField(varName: 'GOOGLE_MAPS_API_KEY', obfuscate: true)
  static final String googleMapsApiKey = _EnvConfig.googleMapsApiKey;

  /// RevenueCat public SDK keys (Google Play / App Store). Optional for local dev.
  @EnviedField(varName: 'REVENUE_CAT_ANDROID_KEY', defaultValue: '', obfuscate: true)
  static final String revenueCatAndroidKey = _EnvConfig.revenueCatAndroidKey;

  @EnviedField(varName: 'REVENUE_CAT_IOS_KEY', defaultValue: '', obfuscate: true)
  static final String revenueCatIosKey = _EnvConfig.revenueCatIosKey;
}
