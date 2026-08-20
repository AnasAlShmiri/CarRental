import 'package:flutter/foundation.dart';

/// Central API configuration for the portable development setup.
///
/// The API runs on port 5109. Android Emulator cannot reach the host machine
/// through localhost, so it uses 10.0.2.2 automatically. For a physical phone,
/// set [physicalDeviceBaseUrl] to the computer's LAN address.
class ApiConfig {
  ApiConfig._();

  /// Optional LAN address for a physical Android/iOS device.
  /// Example: http://192.168.1.5:5109
  static const String? physicalDeviceBaseUrl = null;

  static String get baseUrl {
    if (physicalDeviceBaseUrl != null && physicalDeviceBaseUrl!.isNotEmpty) {
      return physicalDeviceBaseUrl!;
    }

    if (kIsWeb) {
      return 'http://localhost:5109';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5109';
      default:
        return 'http://localhost:5109';
    }
  }

  static String get loginUrl => '$baseUrl/api/auth/login';

  static String resolveUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    return '$baseUrl${pathOrUrl.startsWith('/') ? '' : '/'}$pathOrUrl';
  }
}
