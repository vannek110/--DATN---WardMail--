import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';

class ScanHistoryService {
  static const String _scanHistoryKey = 'scan_history';

  Future<void> saveScanResult(ScanResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getScanHistory();
    history.add(result);
    
    final jsonList = history.map((r) => r.toJson()).toList();
    await prefs.setString(_scanHistoryKey, jsonEncode(jsonList));
  }

  Future<List<ScanResult>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_scanHistoryKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => ScanResult.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final history = await getScanHistory();
    
    if (history.isEmpty) {
      return {
        'totalScanned': 0,
        'phishingCount': 0,
        'suspiciousCount': 0,
        'safeCount': 0,
        'phishingPercentage': 0.0,
        'suspiciousPercentage': 0.0,
        'safePercentage': 0.0,
        'recentScans': [],
        'threatTrends': {},
      };
    }

    final phishingCount = history.where((r) => r.isPhishing).length;
    final suspiciousCount = history.where((r) => r.isSuspicious).length;
    final safeCount = history.where((r) => r.isSafe).length;
    final total = history.length;

    final recentScans = history
      .toList()
      ..sort((a, b) => b.scanDate.compareTo(a.scanDate));
    
    final last7Days = recentScans
        .where((r) => DateTime.now().difference(r.scanDate).inDays <= 7)
        .toList();

    final threatTrends = _calculateThreatTrends(history);

    return {
      'totalScanned': total,
      'phishingCount': phishingCount,
      'suspiciousCount': suspiciousCount,
      'safeCount': safeCount,
      'phishingPercentage': (phishingCount / total * 100),
      'suspiciousPercentage': (suspiciousCount / total * 100),
      'safePercentage': (safeCount / total * 100),
      'recentScans': recentScans.take(10).toList(),
      'last7DaysScans': last7Days,
      'threatTrends': threatTrends,
      'averageConfidence': _calculateAverageConfidence(history),
    };
  }

  Map<String, int> _calculateThreatTrends(List<ScanResult> history) {
    final trends = <String, int>{};
    
    for (var result in history) {
      for (var threat in result.detectedThreats) {
        trends[threat] = (trends[threat] ?? 0) + 1;
      }
    }
    
    return Map.fromEntries(
      trends.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );
  }

  double _calculateAverageConfidence(List<ScanResult> history) {
    if (history.isEmpty) return 0.0;
    final sum = history.fold<double>(0, (sum, r) => sum + r.confidenceScore);
    return sum / history.length;
  }

  Future<List<ScanResult>> getPhishingEmails() async {
    final history = await getScanHistory();
    return history.where((r) => r.isPhishing).toList()
      ..sort((a, b) => b.scanDate.compareTo(a.scanDate));
  }

  Future<List<ScanResult>> getSuspiciousEmails() async {
    final history = await getScanHistory();
    return history.where((r) => r.isSuspicious).toList()
      ..sort((a, b) => b.scanDate.compareTo(a.scanDate));
  }

  Future<Map<String, List<ScanResult>>> getEmailsByDate() async {
    final history = await getScanHistory();
    final Map<String, List<ScanResult>> grouped = {};

    for (var result in history) {
      final dateKey = '${result.scanDate.year}-${result.scanDate.month.toString().padLeft(2, '0')}-${result.scanDate.day.toString().padLeft(2, '0')}';
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(result);
    }

    return grouped;
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scanHistoryKey);
  }

  Future<void> generateMockData() async {
    final mockResults = [
      ScanResult(
        id: '1',
        emailId: 'email1',
        from: 'security@paypal-verify.com',
        subject: 'Urgent: Verify your account',
        scanDate: DateTime.now().subtract(const Duration(days: 1)),
        result: 'phishing',
        confidenceScore: 0.92,
        detectedThreats: ['Suspicious URL', 'Fake sender', 'Urgency tactics'],
        analysisDetails: {'reason': 'Suspicious domain and urgent language'},
      ),
      ScanResult(
        id: '2',
        emailId: 'email2',
        from: 'noreply@google.com',
        subject: 'Your Google Account Security Alert',
        scanDate: DateTime.now().subtract(const Duration(days: 2)),
        result: 'safe',
        confidenceScore: 0.98,
        detectedThreats: [],
        analysisDetails: {'reason': 'Verified sender and legitimate domain'},
      ),
      ScanResult(
        id: '3',
        emailId: 'email3',
        from: 'unknown@tempmail.com',
        subject: 'You won a prize!',
        scanDate: DateTime.now().subtract(const Duration(days: 3)),
        result: 'phishing',
        confidenceScore: 0.89,
        detectedThreats: ['Too good to be true', 'Suspicious domain'],
        analysisDetails: {'reason': 'Lottery scam pattern detected'},
      ),
      ScanResult(
        id: '4',
        emailId: 'email4',
        from: 'support@amazon.com',
        subject: 'Your order has been shipped',
        scanDate: DateTime.now().subtract(const Duration(days: 4)),
        result: 'safe',
        confidenceScore: 0.95,
        detectedThreats: [],
        analysisDetails: {'reason': 'Verified Amazon sender'},
      ),
      ScanResult(
        id: '5',
        emailId: 'email5',
        from: 'info@bank-security.net',
        subject: 'Suspicious activity on your account',
        scanDate: DateTime.now().subtract(const Duration(days: 5)),
        result: 'suspicious',
        confidenceScore: 0.75,
        detectedThreats: ['Suspicious domain', 'Urgent action required'],
        analysisDetails: {'reason': 'Domain doesn\'t match bank\'s official domain'},
      ),
      ScanResult(
        id: '6',
        emailId: 'email6',
        from: 'newsletter@company.com',
        subject: 'Weekly newsletter',
        scanDate: DateTime.now().subtract(const Duration(days: 6)),
        result: 'safe',
        confidenceScore: 0.97,
        detectedThreats: [],
        analysisDetails: {'reason': 'Legitimate newsletter'},
      ),
      ScanResult(
        id: '7',
        emailId: 'email7',
        from: 'admin@microsft-support.com',
        subject: 'Your Microsoft account will be deleted',
        scanDate: DateTime.now().subtract(const Duration(days: 7)),
        result: 'phishing',
        confidenceScore: 0.94,
        detectedThreats: ['Typosquatting', 'Threatening language', 'Fake sender'],
        analysisDetails: {'reason': 'Misspelled domain (microsft vs microsoft)'},
      ),
    ];

    for (var result in mockResults) {
      await saveScanResult(result);
    }
  }
}
