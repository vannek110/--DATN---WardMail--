import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'background_email_service.dart';

/// Service để tự động start monitoring khi cần thiết
class AutoStartService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _autoStartEnabledKey = 'auto_start_enabled';
  static const String _lastStartTimeKey = 'last_start_time';

  /// Kiểm tra xem auto-start có được bật không
  static Future<bool> isAutoStartEnabled() async {
    final value = await _storage.read(key: _autoStartEnabledKey);
    return value == 'true';
  }

  /// Bật auto-start
  static Future<void> enableAutoStart() async {
    await _storage.write(key: _autoStartEnabledKey, value: 'true');
    print('✅ Auto-start enabled');
  }

  /// Tắt auto-start
  static Future<void> disableAutoStart() async {
    await _storage.write(key: _autoStartEnabledKey, value: 'false');
    await BackgroundEmailService.cancelAllTasks();
    print('❌ Auto-start disabled');
  }

  /// Khởi động background service tự động
  static Future<void> startBackgroundService() async {
    try {
      // Check xem đã bật auto-start chưa
      final enabled = await isAutoStartEnabled();
      
      if (!enabled) {
        // Lần đầu tiên, tự động bật
        await enableAutoStart();
      }

      // Register background task
      await BackgroundEmailService.registerPeriodicTask();
      
      // Lưu thời gian start
      await _storage.write(
        key: _lastStartTimeKey,
        value: DateTime.now().toIso8601String(),
      );

      print('✅ Background service auto-started at ${DateTime.now()}');
    } catch (e) {
      print('❌ Failed to auto-start background service: $e');
      rethrow;
    }
  }

  /// Lấy thời gian start cuối cùng
  static Future<DateTime?> getLastStartTime() async {
    try {
      final value = await _storage.read(key: _lastStartTimeKey);
      if (value != null) {
        return DateTime.parse(value);
      }
    } catch (e) {
      print('Error getting last start time: $e');
    }
    return null;
  }

  /// Check và restart nếu cần (gọi khi app khởi động)
  static Future<void> checkAndRestart() async {
    try {
      final enabled = await isAutoStartEnabled();
      
      if (enabled) {
        final lastStart = await getLastStartTime();
        
        // Nếu chưa start hoặc đã lâu (>24h), restart
        if (lastStart == null || 
            DateTime.now().difference(lastStart).inHours > 24) {
          print('🔄 Restarting background service...');
          await startBackgroundService();
        } else {
          print('✓ Background service already running');
        }
      }
    } catch (e) {
      print('Error checking auto-start: $e');
    }
  }
}
