import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiAnalysisService {
  // API Key - NÊN LƯU TRONG .env HOẶC SECURE STORAGE
  // Tạm thời hardcode để test, sau này cần di chuyển ra ngoài
  static const String _apiKey = 'AIzaSyCpfT9gJdmImYpuqorZQTgY1B3xQurc-2Q';
  
  late final GenerativeModel _model;

  GeminiAnalysisService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  /// Bước 6: Gửi email đã làm mờ lên Gemini để phân tích
  Future<GeminiAnalysisResult> analyzeEmail({
    required String anonymizedSubject,
    required String anonymizedBody,
    required String anonymizedFrom,
  }) async {
    try {
      print('=== GEMINI ANALYSIS START ===');
      print('Subject: ${anonymizedSubject.substring(0, anonymizedSubject.length > 50 ? 50 : anonymizedSubject.length)}...');
      
      final prompt = _buildAnalysisPrompt(
        subject: anonymizedSubject,
        body: anonymizedBody,
        from: anonymizedFrom,
      );

      print('Sending request to Gemini...');
      final response = await _model.generateContent([Content.text(prompt)]);
      
      print('Response received!');
      print('Response text length: ${response.text?.length ?? 0}');
      
      if (response.text == null || response.text!.isEmpty) {
        print('ERROR: Empty response from Gemini');
        throw Exception('Không nhận được phản hồi từ Gemini AI');
      }

      print('Parsing response...');
      return _parseGeminiResponse(response.text!);
    } catch (e, stackTrace) {
      print('=== GEMINI ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Lỗi khi phân tích với Gemini: $e');
    }
  }

  String _buildAnalysisPrompt({
    required String subject,
    required String body,
    required String from,
  }) {
    return '''
Phân tích email phishing. Trả về ĐÚNG format JSON dưới đây, KHÔNG thêm text nào khác.

**LƯU Ý:** Tiêu đề và nội dung email đã được làm mờ thông tin cá nhân. Địa chỉ người gửi GIỮ NGUYÊN để bạn phân tích domain.

Người gửi: $from (DOMAIN THẬT - phân tích kỹ)
Tiêu đề: $subject
Nội dung: $body

Trả về JSON theo format SAU (KHÔNG thêm markdown, KHÔNG thêm text):
{
  "risk_score": 15,
  "risk_level": "Low",
  "summary": "Email an toàn từ tổ chức giáo dục",
  "detailed_analysis": {
    "sender_analysis": "Domain giáo dục hợp pháp",
    "content_analysis": "Thông báo chính thức về lịch học",
    "technical_analysis": "Không có link nguy hiểm",
    "context_analysis": "Email thông báo học tập bình thường"
  },
  "red_flags": [],
  "recommendations": ["Email an toàn, có thể đọc"]
}

Đánh giá risk_score:
- 0-25: Low (email an toàn)
- 26-50: Medium (có dấu hiệu đáng ngờ)  
- 51-75: High (nhiều dấu hiệu lừa đảo)
- 76-100: Critical (chắc chắn phishing)

CHỈ trả về JSON, không thêm gì khác.
''';
  }

  GeminiAnalysisResult _parseGeminiResponse(String responseText) {
    try {
      // Loại bỏ markdown code block nếu có
      String jsonText = responseText.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Log để debug
      print('Gemini JSON Response: ${jsonText.substring(0, jsonText.length > 500 ? 500 : jsonText.length)}...');

      final Map<String, dynamic> json = jsonDecode(jsonText);

      // Parse với format mới (risk_score, risk_level, red_flags)
      final riskScore = (json['risk_score'] ?? json['riskScore'] ?? 0).toDouble();
      final riskLevel = json['risk_level'] ?? json['classification'] ?? 'unknown';
      
      // Convert risk_level to classification
      String classification = 'unknown';
      if (riskLevel == 'Low') {
        classification = 'safe';
      } else if (riskLevel == 'Medium') {
        classification = 'suspicious';
      } else if (riskLevel == 'High' || riskLevel == 'Critical') {
        classification = 'phishing';
      }

      // Parse detailed_analysis
      Map<String, String> detailedAnalysis = {};
      if (json['detailed_analysis'] != null) {
        final analysis = json['detailed_analysis'];
        detailedAnalysis = {
          'sender': analysis['sender_analysis']?.toString() ?? '',
          'content': analysis['content_analysis']?.toString() ?? '',
          'technical': analysis['technical_analysis']?.toString() ?? '',
          'context': analysis['context_analysis']?.toString() ?? '',
        };
      }

      // Parse reasons từ summary nếu có
      List<String> reasons = [];
      if (json['summary'] != null) {
        reasons.add(json['summary'].toString());
      }

      return GeminiAnalysisResult(
        riskScore: riskScore,
        classification: classification,
        confidence: 85.0, // Giá trị mặc định vì format mới không có confidence
        reasons: reasons,
        phishingIndicators: json['red_flags'] != null
            ? List<String>.from(json['red_flags'])
            : [],
        recommendations: json['recommendations'] != null
            ? List<String>.from(json['recommendations'])
            : [],
        detailedAnalysis: detailedAnalysis,
        rawResponse: responseText,
      );
    } catch (e, stackTrace) {
      // Log chi tiết để debug
      print('Error parsing Gemini response: $e');
      print('Stack trace: $stackTrace');
      print('Raw response: ${responseText.substring(0, responseText.length > 1000 ? 1000 : responseText.length)}');
      
      // Nếu không parse được JSON, trả về kết quả mặc định
      return GeminiAnalysisResult(
        riskScore: 50,
        classification: 'unknown',
        confidence: 30,
        reasons: ['Không thể phân tích chi tiết: $e'],
        phishingIndicators: [],
        recommendations: ['Cần xem xét thủ công'],
        detailedAnalysis: {},
        rawResponse: responseText,
      );
    }
  }

  /// Test Gemini API connection
  Future<bool> testConnection() async {
    try {
      print('Testing Gemini API connection...');
      final response = await _model.generateContent([
        Content.text('Reply with just: {"status": "ok"}')
      ]);
      
      print('Test response: ${response.text}');
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      print('Test connection failed: $e');
      return false;
    }
  }
}

class GeminiAnalysisResult {
  final double riskScore; // 0-100
  final String classification; // safe, suspicious, phishing
  final double confidence; // 0-100
  final List<String> reasons;
  final List<String> phishingIndicators;
  final List<String> recommendations;
  final Map<String, String> detailedAnalysis;
  final String rawResponse;

  GeminiAnalysisResult({
    required this.riskScore,
    required this.classification,
    required this.confidence,
    required this.reasons,
    required this.phishingIndicators,
    required this.recommendations,
    required this.detailedAnalysis,
    required this.rawResponse,
  });

  bool get isPhishing => classification == 'phishing' || riskScore >= 61;
  bool get isSuspicious => classification == 'suspicious' || (riskScore >= 31 && riskScore < 61);
  bool get isSafe => classification == 'safe' || riskScore < 31;

  Map<String, dynamic> toJson() {
    return {
      'riskScore': riskScore,
      'classification': classification,
      'confidence': confidence,
      'reasons': reasons,
      'phishingIndicators': phishingIndicators,
      'recommendations': recommendations,
      'detailedAnalysis': detailedAnalysis,
      'rawResponse': rawResponse,
    };
  }

  factory GeminiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return GeminiAnalysisResult(
      riskScore: (json['riskScore'] ?? 0).toDouble(),
      classification: json['classification'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      reasons: json['reasons'] != null 
          ? List<String>.from(json['reasons']) 
          : [],
      phishingIndicators: json['phishingIndicators'] != null
          ? List<String>.from(json['phishingIndicators'])
          : [],
      recommendations: json['recommendations'] != null
          ? List<String>.from(json['recommendations'])
          : [],
      detailedAnalysis: json['detailedAnalysis'] != null
          ? Map<String, String>.from(json['detailedAnalysis'])
          : {},
      rawResponse: json['rawResponse'] ?? '',
    );
  }
}
