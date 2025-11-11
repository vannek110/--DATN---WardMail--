import 'dart:math';
import '../models/email_message.dart';
import '../models/scan_result.dart';
import 'anonymization_service.dart';
import 'gemini_analysis_service.dart';

class EmailAnalysisService {
  final AnonymizationService _anonymizationService = AnonymizationService();
  final GeminiAnalysisService _geminiService = GeminiAnalysisService();
  
  bool _useGeminiAI = true; // Flag để bật/tắt Gemini AI
  
  void setUseGeminiAI(bool value) {
    _useGeminiAI = value;
  }
  // Danh sách các domain nguy hiểm thường gặp
  final List<String> _suspiciousDomains = [
    'paypal-verify',
    'account-update',
    'secure-login',
    'verify-account',
    'account-secure',
    'security-check',
    'confirm-identity',
    'suspended-account',
    'urgent-action',
    'temporary-link',
  ];

  // Từ khóa đáng ngờ trong tiêu đề/nội dung
  final List<String> _suspiciousKeywords = [
    'verify your account',
    'urgent action required',
    'suspended',
    'confirm your identity',
    'update your information',
    'click here immediately',
    'your account will be closed',
    'unauthorized activity',
    'suspicious activity',
    'claim your prize',
    'you have won',
    'free money',
    'act now',
    'limited time',
    'expire',
    'reset your password',
    'confirm your payment',
  ];

  // Các domain đáng tin cậy
  final List<String> _trustedDomains = [
    'google.com',
    'gmail.com',
    'microsoft.com',
    'outlook.com',
    'amazon.com',
    'facebook.com',
    'twitter.com',
    'linkedin.com',
    'apple.com',
    'github.com',
  ];

  Future<ScanResult> analyzeEmail(EmailMessage email) async {
    // Reset anonymization service cho email mới
    _anonymizationService.reset();
    
    final threats = <String>[];
    double riskScore = 0.0;
    
    // Kết quả Gemini (nếu sử dụng)
    GeminiAnalysisResult? geminiResult;
    Map<String, dynamic>? anonymizationInfo;

    // 1. Kiểm tra domain người gửi
    final senderDomain = _extractDomain(email.from);
    if (_isSuspiciousDomain(senderDomain)) {
      threats.add('Suspicious domain');
      riskScore += 0.3;
    }

    if (_isTyposquatting(senderDomain)) {
      threats.add('Typosquatting');
      riskScore += 0.35;
    }

    // 2. Kiểm tra tiêu đề email
    final subjectLower = email.subject.toLowerCase();
    int suspiciousKeywordCount = 0;
    for (var keyword in _suspiciousKeywords) {
      if (subjectLower.contains(keyword.toLowerCase())) {
        suspiciousKeywordCount++;
      }
    }

    if (suspiciousKeywordCount > 0) {
      threats.add('Urgency tactics');
      riskScore += suspiciousKeywordCount * 0.1;
    }

    // 3. Kiểm tra nội dung email
    final bodyLower = (email.body ?? email.snippet).toLowerCase();
    
    if (_containsPhishingPatterns(bodyLower)) {
      threats.add('Phishing pattern detected');
      riskScore += 0.25;
    }

    if (_containsSuspiciousLinks(bodyLower)) {
      threats.add('Suspicious URL');
      riskScore += 0.2;
    }

    // 4. Kiểm tra yêu cầu thông tin nhạy cảm
    if (_requestsSensitiveInfo(bodyLower)) {
      threats.add('Requests sensitive information');
      riskScore += 0.25;
    }

    // 5. Kiểm tra tên người gửi vs email
    if (_isSpoofedSender(email.from)) {
      threats.add('Fake sender');
      riskScore += 0.3;
    }

    // 6. Điểm cộng cho domain tin cậy
    if (_isTrustedDomain(senderDomain)) {
      riskScore = max(0, riskScore - 0.4);
    }

    // Tính toán kết quả heuristic
    riskScore = min(1.0, riskScore);
    
    // TÍCH HỢP GEMINI AI
    if (_useGeminiAI) {
      try {
        // Bước 1-5: Làm mờ dữ liệu cá nhân
        anonymizationInfo = _anonymizationService.anonymizeEmail(
          subject: email.subject,
          body: email.body ?? email.snippet,
          from: email.from,
        );

        // Bước 6: Gửi email đã làm mờ lên Gemini
        geminiResult = await _geminiService.analyzeEmail(
          anonymizedSubject: anonymizationInfo['subject'],
          anonymizedBody: anonymizationInfo['body'],
          anonymizedFrom: anonymizationInfo['from'],
        );

        // Kết hợp kết quả heuristic và Gemini
        // Gemini có trọng số 70%, heuristic 30%
        final geminiScore = geminiResult.riskScore / 100.0;
        riskScore = (geminiScore * 0.7) + (riskScore * 0.3);
        
        // Thêm indicators từ Gemini vào threats
        threats.addAll(geminiResult.phishingIndicators);
      } catch (e) {
        // Nếu Gemini lỗi, chỉ dùng heuristic
        print('Lỗi Gemini AI: $e');
      }
    }

    riskScore = min(1.0, riskScore);
    
    String result;
    if (riskScore >= 0.7) {
      result = 'phishing';
    } else if (riskScore >= 0.4) {
      result = 'suspicious';
    } else {
      result = 'safe';
    }

    // Nếu là email an toàn, đảo ngược confidence score
    final confidenceScore = result == 'safe' 
        ? 1.0 - riskScore 
        : riskScore;

    // Tạo analysis details
    final analysisDetails = {
      'senderDomain': senderDomain,
      'riskScore': riskScore,
      'suspiciousKeywordCount': suspiciousKeywordCount,
      'analysisDate': DateTime.now().toIso8601String(),
      'usedGeminiAI': _useGeminiAI && geminiResult != null,
    };

    // Thêm kết quả Gemini nếu có
    if (geminiResult != null) {
      analysisDetails['gemini'] = {
        'riskScore': geminiResult.riskScore,
        'classification': geminiResult.classification,
        'confidence': geminiResult.confidence,
        'reasons': geminiResult.reasons,
        'recommendations': geminiResult.recommendations,
        'detailedAnalysis': geminiResult.detailedAnalysis,
      };
    }

    // Thêm thông tin anonymization nếu có
    if (anonymizationInfo != null) {
      analysisDetails['anonymization'] = {
        'entityCount': anonymizationInfo['entityCount'],
        'hasPersonalData': (anonymizationInfo['entityCount'] as Map).values.any((count) => count > 0),
      };
    }

    return ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emailId: email.id,
      from: email.from,
      subject: email.subject,
      scanDate: DateTime.now(),
      result: result,
      confidenceScore: confidenceScore,
      detectedThreats: threats.toSet().toList(), // Remove duplicates
      analysisDetails: analysisDetails,
    );
  }

  String _extractDomain(String email) {
    final match = RegExp(r'@([a-zA-Z0-9.-]+)').firstMatch(email);
    return match?.group(1)?.toLowerCase() ?? '';
  }

  bool _isSuspiciousDomain(String domain) {
    return _suspiciousDomains.any((suspicious) => 
      domain.contains(suspicious.toLowerCase())
    );
  }

  bool _isTyposquatting(String domain) {
    // Kiểm tra các trường hợp typosquatting phổ biến
    final commonTypos = {
      'gooogle': 'google',
      'paypa1': 'paypal',
      'microsft': 'microsoft',
      'amazom': 'amazon',
      'faceboook': 'facebook',
      'app1e': 'apple',
    };

    for (var entry in commonTypos.entries) {
      if (domain.contains(entry.key)) {
        return true;
      }
    }

    return false;
  }

  bool _isTrustedDomain(String domain) {
    return _trustedDomains.any((trusted) => 
      domain.endsWith(trusted)
    );
  }

  bool _containsPhishingPatterns(String text) {
    final phishingPatterns = [
      'click here',
      'verify now',
      'update payment',
      'confirm account',
      'suspended account',
      'unusual activity',
      'security alert',
      'action required',
    ];

    return phishingPatterns.any((pattern) => 
      text.contains(pattern.toLowerCase())
    );
  }

  bool _containsSuspiciousLinks(String text) {
    // Kiểm tra link rút gọn hoặc link đáng ngờ
    final suspiciousLinkPatterns = [
      'bit.ly',
      'tinyurl',
      'goo.gl',
      't.co',
      'ow.ly',
      'is.gd',
      'buff.ly',
      'adf.ly',
    ];

    return suspiciousLinkPatterns.any((pattern) => 
      text.contains(pattern)
    );
  }

  bool _requestsSensitiveInfo(String text) {
    final sensitiveRequests = [
      'social security',
      'credit card',
      'bank account',
      'password',
      'pin number',
      'date of birth',
      'ssn',
      'cvv',
      'account number',
      'routing number',
    ];

    return sensitiveRequests.any((request) => 
      text.contains(request.toLowerCase())
    );
  }

  bool _isSpoofedSender(String from) {
    // Kiểm tra xem tên hiển thị có khớp với email không
    if (from.contains('<') && from.contains('>')) {
      final displayName = from.substring(0, from.indexOf('<')).toLowerCase();
      final email = from.substring(from.indexOf('<') + 1, from.indexOf('>')).toLowerCase();
      
      // Nếu tên hiển thị chứa các từ khóa quan trọng nhưng email không khớp
      final importantNames = ['paypal', 'google', 'microsoft', 'amazon', 'bank'];
      
      for (var name in importantNames) {
        if (displayName.contains(name) && !email.contains(name)) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Phân tích nhanh để hiển thị cảnh báo sơ bộ
  Future<Map<String, dynamic>> quickAnalysis(EmailMessage email) async {
    final senderDomain = _extractDomain(email.from);
    final subjectLower = email.subject.toLowerCase();
    
    bool hasWarning = false;
    final warnings = <String>[];

    if (_isSuspiciousDomain(senderDomain)) {
      hasWarning = true;
      warnings.add('Domain đáng ngờ');
    }

    if (_suspiciousKeywords.any((k) => subjectLower.contains(k.toLowerCase()))) {
      hasWarning = true;
      warnings.add('Tiêu đề khẩn cấp');
    }

    return {
      'hasWarning': hasWarning,
      'warnings': warnings,
      'senderDomain': senderDomain,
    };
  }
}
