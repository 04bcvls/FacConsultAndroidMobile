import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:andfacconsult/utils/logger.dart';

/// Manages device identification for guest users
class DeviceIdentifier {
  static const String _deviceIdKey = 'andfac_device_id';

  /// Get or create a unique device ID for this device
  static Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if device ID already exists
      String? existingDeviceId = prefs.getString(_deviceIdKey);
      
      if (existingDeviceId != null && existingDeviceId.isNotEmpty) {
        logInfo('Retrieved existing device ID: ${existingDeviceId.substring(0, 8)}...');
        return existingDeviceId;
      }
      
      // Generate new device ID
      final newDeviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, newDeviceId);
      
      logInfo('Generated new device ID: ${newDeviceId.substring(0, 8)}...');
      return newDeviceId;
    } catch (e, stackTrace) {
      logError('Error getting device ID', e, stackTrace);
      // Fallback: generate temporary UUID
      return const Uuid().v4();
    }
  }

  /// Clear device ID (for testing purposes)
  static Future<void> clearDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deviceIdKey);
      logInfo('Device ID cleared');
    } catch (e, stackTrace) {
      logError('Error clearing device ID', e, stackTrace);
    }
  }

  /// Get device ID without async (after first load)
  static String? getCachedDeviceId() {
    // This would need to be cached at app startup if you want sync access
    return null;
  }
}
