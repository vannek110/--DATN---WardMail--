import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiAnalysisService {
  // API Key - NÊN LƯU TRONG .env HOẶC SECURE STORAGE
  // Tạm thời hardcode để test, sau này cần di chuyển ra ngoài
  static const String _apiKey = 'AIzaSyBcFkPZWI0npRvYiQ55tZHSG_cm79Vv_5A';
  
  // Danh sách models để fallback nếu model chính lỗi
  static const List<String> _availableModels = [
    'gemini-2.5-flash',      // Model mới nhất, nhanh nhất (stable 2025)
    'gemini-2.5-pro',        // Model mạnh hơn nhưng chậm hơn
    'gemini-2.0-flash-001',  // Model fallback cũ hơn
    'gemini-1.5-flash',      // Model cũ nhất
  ];
  
  late GenerativeModel _model;
  String _currentModel = _availableModels[0];

  GeminiAnalysisService() {
    _model = GenerativeModel(
      model: _currentModel,
      apiKey: _apiKey,
    );
  }
  
  /// Thử đổi sang model khác nếu model hiện tại lỗi
  void _switchToFallbackModel() {
    final currentIndex = _availableModels.indexOf(_currentModel);
    if (currentIndex < _availableModels.length - 1) {
      _currentModel = _availableModels[currentIndex + 1];
      _model = GenerativeModel(
        model: _currentModel,
        apiKey: _apiKey,
      );
      print('Switched to fallback model: $_currentModel');
    } else {
      throw Exception('Đã thử tất cả models nhưng đều lỗi');
    }
  }

  /// Bước 6: Gửi email đã làm mờ lên Gemini để phân tích
  Future<GeminiAnalysisResult> analyzeEmail({
    required String anonymizedSubject,
    required String anonymizedBody,
    required String anonymizedFrom,
  }) async {
    int maxRetries = _availableModels.length; // Thử tất cả models
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        print('=== GEMINI ANALYSIS START (Model: $_currentModel) ===');
        print('Attempt: ${attempt + 1}/$maxRetries');
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
        final result = _parseGeminiResponse(response.text!);
        
        // Nếu kết quả có classification unknown, có thể do lỗi parse - thử lại với prompt đơn giản hơn
        if (result.classification == 'unknown' && result.confidence < 50) {
          print('First attempt resulted in unknown classification, retrying with simpler prompt...');
          return await _retryWithSimplePrompt(
            subject: anonymizedSubject,
            body: anonymizedBody,
            from: anonymizedFrom,
          );
        }
        
        print('=== ANALYSIS SUCCESS ===');
        return result;
        
      } catch (e) {
        print('=== GEMINI ERROR (Attempt ${attempt + 1}) ===');
        print('Current Model: $_currentModel');
        print('Error: $e');
        
        // Nếu còn model để thử, switch sang model khác
        if (attempt < maxRetries - 1) {
          try {
            _switchToFallbackModel();
            print('Retrying with fallback model: $_currentModel');
            attempt++;
            continue;
          } catch (switchError) {
            // Hết models để thử
            throw Exception('Đã thử tất cả models nhưng đều lỗi: $e');
          }
        } else {
          // Đã thử hết, throw error cuối cùng
          throw Exception('Lỗi khi phân tích với Gemini: $e');
        }
      }
    }
    
    // Không bao giờ tới đây, nhưng Dart yêu cầu return
    throw Exception('Unexpected error in analyzeEmail');
  }

  /// Thử lại với prompt đơn giản hơn, chỉ yêu cầu thông tin cơ bản
  Future<GeminiAnalysisResult> _retryWithSimplePrompt({
    required String subject,
    required String body,
    required String from,
  }) async {
    final simplePrompt = '''
Phân tích email này. Chỉ trả về JSON hợp lệ, không gì khác.

Từ: $from
Tiêu đề: $subject
Nội dung: $body

Trả về CHÍNH XÁC format JSON này (dùng nháy đơn '' trong text, KHÔNG dùng ngoặc kép ""):
{
  "risk_score": 50,
  "risk_level": "Medium",
  "summary": "Tóm tắt ngắn gọn một dòng",
  "red_flags": [],
  "recommendations": ["Một khuyến nghị"]
}

risk_score: 0-100 (0=an toàn, 100=nguy hiểm)
risk_level: Low / Medium / High / Critical

CHỈ TRẢ VỀ JSON HỢP LỆ. KHÔNG MARKDOWN. KHÔNG TEXT THỪA.
''';

    print('Sending simplified request...');
    final response = await _model.generateContent([Content.text(simplePrompt)]);
    
    if (response.text == null || response.text!.isEmpty) {
      throw Exception('Không nhận được phản hồi từ Gemini khi retry');
    }
    
    return _parseGeminiResponse(response.text!);
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

**QUAN TRỌNG về JSON:**
- BẮT BUỘC: JSON phải hợp lệ 100%
- Nội dung TIẾNG VIỆT là OK, nhưng KHÔNG ĐƯỢC có dấu ngoặc kép (") trong nội dung text
- Nếu cần trích dẫn, dùng dấu nháy đơn ('')
- KHÔNG xuống dòng trong string values, viết trên một dòng
- Ví dụ SAI: "content": "Email có link "click here" nguy hiểm"
- Ví dụ ĐÚNG: "content": "Email có link 'click here' nguy hiểm"

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
  "recommendations": ["Email an toàn có thể đọc"]
}

Đánh giá risk_score:
- 0-25: Low (email an toàn)
- 26-50: Medium (có dấu hiệu đáng ngờ)  
- 51-75: High (nhiều dấu hiệu lừa đảo)
- 76-100: Critical (chắc chắn phishing)

CHỈ trả về JSON VALID, không thêm gì khác. Kiểm tra lại JSON trước khi trả về.
''';
  }

  /// Làm sạch chuỗi JSON để tránh lỗi parsing - hỗ trợ tiếng Việt
  String _cleanJsonString(String jsonText) {
    // Loại bỏ các ký tự điều khiển không hợp lệ (trừ \n, \r, \t)
    jsonText = jsonText.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ' ');
    
    // Sửa các newline không hợp lệ trong JSON string values
    // Tìm tất cả cặp dấu ngoặc kép và replace newline bên trong
    jsonText = _fixNewlinesInStrings(jsonText);
    
    // Sửa các dấu ngoặc kép chưa escape trong string values
    jsonText = _fixUnescapedQuotes(jsonText);
    
    return jsonText.trim();
  }

  /// Sửa newline không hợp lệ trong JSON strings
  String _fixNewlinesInStrings(String text) {
    final buffer = StringBuffer();
    bool inString = false;
    bool escaped = false;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }
      
      if (char == '\\') {
        buffer.write(char);
        escaped = true;
        continue;
      }
      
      if (char == '"') {
        inString = !inString;
        buffer.write(char);
        continue;
      }
      
      // Nếu đang trong string và gặp newline, thay bằng khoảng trắng
      if (inString && (char == '\n' || char == '\r')) {
        buffer.write(' ');
      } else {
        buffer.write(char);
      }
    }
    
    return buffer.toString();
  }

  /// Cố gắng sửa dấu ngoặc kép chưa escape trong string
  /// Chỉ xử lý các trường hợp rõ ràng để tránh phá JSON hợp lệ
  String _fixUnescapedQuotes(String text) {
    // Pattern phức tạp để detect unescaped quotes
    // Cách đơn giản: nếu có pattern ": "text "more text", sửa thành ": "text 'more text"
    
    // Thay thế " thành ' nếu nó xuất hiện giữa một cặp dấu ngoặc kép của value
    // Ví dụ: "content": "Nội dung tạo cảm giác "hết han" và dễ dọa"
    // Sửa thành: "content": "Nội dung tạo cảm giác 'hết han' và dễ dọa"
    
    final pattern = RegExp(r':\s*"([^"]*)"([^"]*)"([^"]*)"([^,}\]]*)');
    
    String result = text;
    int maxIterations = 10; // Giới hạn để tránh infinite loop
    int iteration = 0;
    
    while (pattern.hasMatch(result) && iteration < maxIterations) {
      result = result.replaceAllMapped(pattern, (match) {
        // Nếu có dấu " giữa chuỗi, convert thành '
        final part1 = match.group(1);
        final part2 = match.group(2);
        final part3 = match.group(3);
        final part4 = match.group(4);
        
        // Check xem có phải trường hợp cần fix không
        if (part2 != null && part2.trim().isNotEmpty && 
            !part2.startsWith(',') && !part2.startsWith('}') && !part2.startsWith(']')) {
          // Đây có thể là unescaped quote
          return ': "$part1 $part2 $part3"$part4';
        }
        
        return match.group(0)!;
      });
      iteration++;
    }
    
    return result;
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

      // Làm sạch JSON - xử lý các vấn đề thường gặp
      jsonText = _cleanJsonString(jsonText);

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
      
      // Thử phân tích một phần nếu có thể
      String errorMessage = 'Lỗi phân tích JSON';
      if (e is FormatException) {
        errorMessage = 'Định dạng JSON không hợp lệ';
        // Thử trích xuất thông tin cơ bản từ text
        final riskScoreMatch = RegExp(r'"risk_score"\s*:\s*(\d+)').firstMatch(responseText);
        final summaryMatch = RegExp(r'"summary"\s*:\s*"([^"]*)"').firstMatch(responseText);
        
        if (riskScoreMatch != null) {
          final extractedScore = double.tryParse(riskScoreMatch.group(1) ?? '50') ?? 50;
          final extractedSummary = summaryMatch?.group(1) ?? 'Không thể phân tích đầy đủ';
          
          print('Extracted partial data: score=$extractedScore, summary=$extractedSummary');
          
          return GeminiAnalysisResult(
            riskScore: extractedScore,
            classification: extractedScore < 30 ? 'safe' : (extractedScore < 60 ? 'suspicious' : 'phishing'),
            confidence: 50,
            reasons: [extractedSummary],
            phishingIndicators: [],
            recommendations: ['Phân tích không hoàn chỉnh - nên kiểm tra lại'],
            detailedAnalysis: {},
            rawResponse: responseText,
          );
        }
      }
      
      // Nếu không parse được gì, trả về kết quả mặc định
      return GeminiAnalysisResult(
        riskScore: 50,
        classification: 'unknown',
        confidence: 30,
        reasons: ['$errorMessage - vui lòng thử lại'],
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
