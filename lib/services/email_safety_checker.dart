import '../models/safety_check_result.dart';

class EmailSafetyChecker {
  /// Main method to check email safety across all 5 criteria
  static SafetyCheckResult check({
    required String subject,
    required String body,
    String locale = 'en',
  }) {
    final pii = _checkPIIProtection(subject, body, locale);
    final phishing = _checkAntiPhishing(subject, body, locale);
    final accuracy = _checkInformationAccuracy(subject, body, locale);
    final tone = _checkProfessionalTone(subject, body, locale);
    final compliance = _checkCompliance(subject, body, locale);

    return SafetyCheckResult(
      piiProtection: pii['pass'] as bool,
      antiPhishing: phishing['pass'] as bool,
      informationAccuracy: accuracy['pass'] as bool,
      professionalTone: tone['pass'] as bool,
      compliance: compliance['pass'] as bool,
      piiMessage: pii['message'] as String,
      phishingMessage: phishing['message'] as String,
      accuracyMessage: accuracy['message'] as String,
      toneMessage: tone['message'] as String,
      complianceMessage: compliance['message'] as String,
      piiDetails: pii['details'] as List<String>,
      phishingDetails: phishing['details'] as List<String>,
      accuracyDetails: accuracy['details'] as List<String>,
      toneDetails: tone['details'] as List<String>,
      complianceDetails: compliance['details'] as List<String>,
    );
  }

  /// Check 1: PII Protection - Scan for sensitive data
  static Map<String, dynamic> _checkPIIProtection(
    String subject,
    String body,
    String locale,
  ) {
    final text = '$subject $body';
    final details = <String>[];

    // Check for credit card patterns
    final creditCardPattern = RegExp(
      r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b',
    );
    if (creditCardPattern.hasMatch(text)) {
      details.add(
        locale == 'vi'
            ? 'Phát hiện số thẻ tín dụng'
            : 'Credit card number detected',
      );
    }

    // Check for SSN patterns
    final ssnPattern = RegExp(r'\b\d{3}-\d{2}-\d{4}\b');
    if (ssnPattern.hasMatch(text)) {
      details.add(
        locale == 'vi' ? 'Phát hiện số an sinh xã hội' : 'SSN detected',
      );
    }

    // Check for password keywords
    final passwordKeywords = ['password:', 'pwd:', 'pass:', 'mật khẩu:'];
    for (final keyword in passwordKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        details.add(
          locale == 'vi'
              ? 'Phát hiện từ khóa mật khẩu'
              : 'Password keyword detected',
        );
        break;
      }
    }

    // Check for bank account patterns
    final bankAccountPattern = RegExp(r'\b\d{10,16}\b');
    final matches = bankAccountPattern.allMatches(text);
    if (matches.length > 1) {
      details.add(
        locale == 'vi'
            ? 'Có thể chứa số tài khoản ngân hàng'
            : 'Possible bank account number',
      );
    }

    final pass = details.isEmpty;
    final message = pass
        ? (locale == 'vi'
              ? 'Không phát hiện dữ liệu nhạy cảm'
              : 'No sensitive data detected')
        : (locale == 'vi'
              ? 'Phát hiện dữ liệu nhạy cảm'
              : 'Sensitive data found');

    return {'pass': pass, 'message': message, 'details': details};
  }

  /// Check 2: Anti-Phishing - Detect phishing indicators
  static Map<String, dynamic> _checkAntiPhishing(
    String subject,
    String body,
    String locale,
  ) {
    final details = <String>[];

    // Check for threatening subject keywords
    final threateningKeywords = [
      'urgent',
      'khẩn cấp',
      'final warning',
      'cảnh báo cuối',
      'suspended',
      'bị khóa',
      'verify now',
      'xác minh ngay',
      'account locked',
      'tài khoản bị khóa',
      'immediate action',
      'hành động ngay',
    ];

    for (final keyword in threateningKeywords) {
      if (subject.toLowerCase().contains(keyword)) {
        details.add(
          locale == 'vi'
              ? 'Tiêu đề mang tính đe dọa: "$keyword"'
              : 'Threatening subject: "$keyword"',
        );
        break;
      }
    }

    // Check for suspicious URLs
    final suspiciousUrls = ['bit.ly', 'tinyurl', 't.co', 'goo.gl', 'ow.ly'];
    final text = '$subject $body'.toLowerCase();
    for (final url in suspiciousUrls) {
      if (text.contains(url)) {
        details.add(
          locale == 'vi'
              ? 'URL rút gọn đáng ngờ: $url'
              : 'Suspicious shortened URL: $url',
        );
      }
    }

    // Check for impersonation keywords
    final impersonationKeywords = [
      'verify your account',
      'xác minh tài khoản',
      'confirm your identity',
      'xác nhận danh tính',
      'update your information',
      'cập nhật thông tin',
      'click here immediately',
      'nhấp vào đây ngay',
    ];

    for (final keyword in impersonationKeywords) {
      if (text.contains(keyword)) {
        details.add(
          locale == 'vi'
              ? 'Ngôn ngữ giả mạo phát hiện'
              : 'Impersonation language detected',
        );
        break;
      }
    }

    // Check for excessive urgency
    final urgencyCount = RegExp(r'!!!+').allMatches(text).length;
    if (urgencyCount > 2) {
      details.add(
        locale == 'vi'
            ? 'Quá nhiều dấu chấm than (!!!)'
            : 'Excessive exclamation marks (!!!)',
      );
    }

    final pass = details.isEmpty;
    final message = pass
        ? (locale == 'vi'
              ? 'Không phát hiện dấu hiệu lừa đảo'
              : 'No phishing indicators detected')
        : (locale == 'vi'
              ? 'Phát hiện dấu hiệu lừa đảo'
              : 'Phishing indicators detected');

    return {'pass': pass, 'message': message, 'details': details};
  }

  /// Check 3: Information Accuracy - Verify claims
  static Map<String, dynamic> _checkInformationAccuracy(
    String subject,
    String body,
    String locale,
  ) {
    final text = '$subject $body';
    final details = <String>[];

    // Check for unverified guarantees
    final guaranteeKeywords = [
      'guaranteed',
      'đảm bảo 100%',
      '100% certain',
      'chắc chắn 100%',
      'absolutely free',
      'hoàn toàn miễn phí',
      'risk-free',
      'không rủi ro',
    ];

    for (final keyword in guaranteeKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        details.add(
          locale == 'vi'
              ? 'Tuyên bố chưa xác minh: "$keyword"'
              : 'Unverified claim: "$keyword"',
        );
      }
    }

    // Check for specific prices without context
    final pricePattern = RegExp(r'\$\d+|\d+\s*(USD|VND|đ)');
    final priceMatches = pricePattern.allMatches(text);
    if (priceMatches.length > 3) {
      details.add(
        locale == 'vi'
            ? 'Nhiều giá cả chưa xác minh'
            : 'Multiple unverified prices',
      );
    }

    // Check for delivery promises
    final deliveryKeywords = [
      'delivered in',
      'giao trong',
      'ships within',
      'vận chuyển trong',
      'arrives by',
      'đến vào',
    ];

    for (final keyword in deliveryKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        details.add(
          locale == 'vi'
              ? 'Cam kết giao hàng chưa xác minh'
              : 'Unverified delivery promise',
        );
        break;
      }
    }

    final pass = details.isEmpty;
    final message = pass
        ? (locale == 'vi'
              ? 'Thông tin có thể xác minh'
              : 'Information appears verifiable')
        : (locale == 'vi'
              ? 'Thông tin chưa xác minh'
              : 'Unverified information detected');

    return {'pass': pass, 'message': message, 'details': details};
  }

  /// Check 4: Professional Tone - Analyze language
  static Map<String, dynamic> _checkProfessionalTone(
    String subject,
    String body,
    String locale,
  ) {
    final text = '$subject $body';
    final details = <String>[];

    // Check for threatening language
    final threateningPhrases = [
      'or else',
      'hoặc là',
      'last chance',
      'cơ hội cuối',
      'you must',
      'bạn phải',
      'immediately',
      'ngay lập tức',
    ];

    for (final phrase in threateningPhrases) {
      if (text.toLowerCase().contains(phrase)) {
        details.add(
          locale == 'vi'
              ? 'Ngôn ngữ đe dọa: "$phrase"'
              : 'Threatening language: "$phrase"',
        );
      }
    }

    // Check for excessive caps (>30% uppercase)
    final letters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.isNotEmpty) {
      final upperCount = letters
          .split('')
          .where((c) => c == c.toUpperCase())
          .length;
      final capsPercentage = (upperCount / letters.length) * 100;
      if (capsPercentage > 30) {
        details.add(
          locale == 'vi'
              ? 'Quá nhiều chữ IN HOA (${capsPercentage.toStringAsFixed(0)}%)'
              : 'Excessive CAPS (${capsPercentage.toStringAsFixed(0)}%)',
        );
      }
    }

    // Check for unprofessional phrases
    final unprofessionalPhrases = [
      'asap',
      'nhanh lên',
      'hurry up',
      'mau lên',
      'act now',
      'hành động ngay',
    ];

    for (final phrase in unprofessionalPhrases) {
      if (text.toLowerCase().contains(phrase)) {
        details.add(
          locale == 'vi'
              ? 'Cụm từ thiếu chuyên nghiệp'
              : 'Unprofessional phrase detected',
        );
        break;
      }
    }

    final pass = details.isEmpty;
    final message = pass
        ? (locale == 'vi'
              ? 'Văn phong chuyên nghiệp'
              : 'Professional tone maintained')
        : (locale == 'vi'
              ? 'Văn phong thiếu chuyên nghiệp'
              : 'Unprofessional tone detected');

    return {'pass': pass, 'message': message, 'details': details};
  }

  /// Check 5: Compliance - Legal requirements
  static Map<String, dynamic> _checkCompliance(
    String subject,
    String body,
    String locale,
  ) {
    final text = '$subject $body'.toLowerCase();
    final details = <String>[];

    // For marketing emails, check for unsubscribe option
    final marketingKeywords = [
      'offer',
      'sale',
      'discount',
      'promotion',
      'khuyến mãi',
      'giảm giá',
    ];
    final isMarketing = marketingKeywords.any((k) => text.contains(k));

    if (isMarketing) {
      final hasUnsubscribe =
          text.contains('unsubscribe') || text.contains('hủy đăng ký');
      if (!hasUnsubscribe) {
        details.add(
          locale == 'vi'
              ? 'Email marketing thiếu tùy chọn hủy đăng ký'
              : 'Marketing email missing unsubscribe option',
        );
      }
    }

    // Check for privacy policy reference in sensitive contexts
    final sensitiveKeywords = [
      'personal data',
      'dữ liệu cá nhân',
      'information',
      'thông tin',
    ];
    final hasSensitiveContent = sensitiveKeywords.any((k) => text.contains(k));

    if (hasSensitiveContent && body.length > 500) {
      final hasPrivacyRef =
          text.contains('privacy') || text.contains('quyền riêng tư');
      if (!hasPrivacyRef) {
        details.add(
          locale == 'vi'
              ? 'Thiếu tham chiếu chính sách bảo mật'
              : 'Missing privacy policy reference',
        );
      }
    }

    // Generally pass compliance unless specific violations found
    final pass = details.isEmpty;
    final message = pass
        ? (locale == 'vi'
              ? 'Tuân thủ các quy định'
              : 'Compliant with regulations')
        : (locale == 'vi'
              ? 'Có thể vi phạm quy định'
              : 'Potential compliance issues');

    return {'pass': pass, 'message': message, 'details': details};
  }
}
