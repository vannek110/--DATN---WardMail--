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
      generationConfig: GenerationConfig(
        temperature: 0.3,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
  }

  /// Bước 6: Gửi email đã làm mờ lên Gemini để phân tích
  Future<GeminiAnalysisResult> analyzeEmail({
    required String anonymizedSubject,
    required String anonymizedBody,
    required String anonymizedFrom,
  }) async {
    try {
      final prompt = _buildAnalysisPrompt(
        subject: anonymizedSubject,
        body: anonymizedBody,
        from: anonymizedFrom,
      );

      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Không nhận được phản hồi từ Gemini AI');
      }

      return _parseGeminiResponse(response.text!);
    } catch (e) {
      throw Exception('Lỗi khi phân tích với Gemini: $e');
    }
  }

  String _buildAnalysisPrompt({
    required String subject,
    required String body,
    required String from,
  }) {
    return '''
Bạn là chuyên gia an ninh mạng chuyên phát hiện email lừa đảo (phishing). 
Hãy phân tích email sau đây và đánh giá mức độ nguy hiểm.

LƯU Ý: Email này đã được làm mờ dữ liệu cá nhân để bảo vệ privacy.

**THÔNG TIN EMAIL:**
Người gửi: $from
Tiêu đề: $subject
Nội dung:
$body

**YÊU CẦU PHÂN TÍCH:**
Đánh giá email theo các tiêu chí sau và trả về kết quả dưới dạng JSON:

1. **Điểm số tổng thể (riskScore):** Từ 0-100
   - 0-30: An toàn (safe)
   - 31-60: Nghi ngờ (suspicious)
   - 61-100: Nguy hiểm/Phishing (phishing)

2. **Phân loại (classification):** "safe", "suspicious", hoặc "phishing"

3. **Mức độ tin cậy (confidence):** Từ 0-100 (độ chắc chắn của phân tích)

4. **Lý do chi tiết (reasons):** Danh sách các lý do cụ thể

5. **Dấu hiệu phishing (phishingIndicators):** Danh sách các dấu hiệu phát hiện được

6. **Khuyến nghị (recommendations):** Các hành động nên làm

**ĐỊNH DẠNG TRẢ VỀ (JSON):**
{
  "riskScore": <số từ 0-100>,
  "classification": "<safe|suspicious|phishing>",
  "confidence": <số từ 0-100>,
  "reasons": [
    "Lý do 1",
    "Lý do 2"
  ],
  "phishingIndicators": [
    "Dấu hiệu 1",
    "Dấu hiệu 2"
  ],
  "recommendations": [
    "Khuyến nghị 1",
    "Khuyến nghị 2"
  ],
  "detailedAnalysis": {
    "sender": "<phân tích người gửi>",
    "subject": "<phân tích tiêu đề>",
    "content": "<phân tích nội dung>",
    "urgency": "<mức độ khẩn cấp>",
    "legitimacy": "<tính hợp pháp>"
  }
}

Chỉ trả về JSON, không kèm thêm text nào khác.
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

      final Map<String, dynamic> json = jsonDecode(jsonText);

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
            ? Map<String, String>.from(json['detailedAnalysis'].map(
                (key, value) => MapEntry(key.toString(), value.toString())
              ))
            : {},
        rawResponse: responseText,
      );
    } catch (e) {
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

  /// Phân tích nhanh với prompt ngắn gọn hơn
  Future<GeminiAnalysisResult> quickAnalyze({
    required String subject,
    required String from,
  }) async {
    try {
      final prompt = '''
Phân tích nhanh email phishing:
Từ: $from
Tiêu đề: $subject

Trả về JSON với: riskScore (0-100), classification (safe/suspicious/phishing), reasons (array).
Chỉ trả JSON, không text khác.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Không nhận được phản hồi');
      }

      return _parseGeminiResponse(response.text!);
    } catch (e) {
      throw Exception('Lỗi phân tích nhanh: $e');
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
