import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service để quản lý feedback của người dùng về kết quả phân tích email
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _feedbackKey = 'email_feedback_history';

  /// Lưu feedback mới
  Future<void> saveFeedback({
    required String emailId,
    required String feedback,
    required String analysisResult,
  }) async {
    final history = await _getAllFeedback();

    history.add({
      'emailId': emailId,
      'feedback': feedback,
      'analysisResult': analysisResult,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _storage.write(key: _feedbackKey, value: jsonEncode(history));
  }

  /// Lấy feedback history cho một email cụ thể
  Future<List<Map<String, dynamic>>> getFeedbackForEmail(String emailId) async {
    final allFeedback = await _getAllFeedback();
    return allFeedback.where((fb) => fb['emailId'] == emailId).toList()..sort(
      (a, b) => DateTime.parse(
        b['timestamp'],
      ).compareTo(DateTime.parse(a['timestamp'])),
    );
  }

  /// Lấy tất cả feedback
  Future<List<Map<String, dynamic>>> _getAllFeedback() async {
    try {
      final data = await _storage.read(key: _feedbackKey);
      if (data == null || data.isEmpty) return [];

      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading feedback: $e');
      return [];
    }
  }

  /// Xóa tất cả feedback
  Future<void> clearAllFeedback() async {
    await _storage.delete(key: _feedbackKey);
  }

  /// Lấy thống kê feedback
  Future<Map<String, int>> getFeedbackStats() async {
    final allFeedback = await _getAllFeedback();
    final stats = <String, int>{
      'total': allFeedback.length,
      'phishing': 0,
      'suspicious': 0,
      'safe': 0,
    };

    for (final fb in allFeedback) {
      final result = fb['analysisResult'] as String?;
      if (result == 'phishing') {
        stats['phishing'] = (stats['phishing'] ?? 0) + 1;
      } else if (result == 'suspicious') {
        stats['suspicious'] = (stats['suspicious'] ?? 0) + 1;
      } else if (result == 'safe') {
        stats['safe'] = (stats['safe'] ?? 0) + 1;
      }
    }

    return stats;
  }
}
