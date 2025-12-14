/// ==============================================================================
/// MODULE: DATA PRIVACY & ANONYMIZATION ENGINE
/// CLASSIFICATION: CRITICAL SECURITY COMPONENT
/// ==============================================================================
///
/// [Mục đích]:
/// Class này chịu trách nhiệm "làm sạch" dữ liệu (Sanitization) trước khi gửi
/// nội dung email tới các dịch vụ AI bên thứ ba (như Google Gemini).
///
/// [Nguyên lý hoạt động]:
/// Sử dụng kỹ thuật "Rule-based NER" (Named Entity Recognition dựa trên luật)
/// kết hợp với "Consistent Replacement" (Thay thế nhất quán).
///
/// [Chính sách Bảo mật]:
/// 1. Tuyệt đối không gửi PII (Personally Identifiable Information) thô ra ngoài.
/// 2. Giữ nguyên ngữ cảnh: Nếu "Ông A" xuất hiện 2 lần, cả 2 lần đều phải
///    được thay thế bằng cùng một giá trị giả (VD: "Nguyễn Văn Đông") để AI
///    hiểu được mạch câu chuyện.
class AnonymizationService {
  // [STATE MANAGEMENT - CONSISTENCY MAPPING]
  // Các Map này lưu trữ trạng thái phiên làm việc hiện tại.
  // Key: Dữ liệu gốc (VD: "0901234567")
  // Value: Dữ liệu giả (VD: "000000001")
  // -> Đảm bảo tính nhất quán (Consistency) trong toàn bộ văn bản.
  final Map<String, String> _personMapping = {};
  final Map<String, String> _phoneMapping = {};
  final Map<String, String> _emailMapping = {};
  final Map<String, String> _locationMapping = {};
  final Map<String, String> _idMapping = {};
  final Map<String, String> _urlMapping = {};
  final Map<String, String> _dateMapping = {};

  // Bộ đếm để sinh dữ liệu giả tăng dần (Sequential Generation)
  int _personCounter = 1;
  int _phoneCounter = 1;
  int _emailCounter = 1;
  int _locationCounter = 1;
  int _idCounter = 1;
  int _urlCounter = 1;
  int _dateCounter = 1;

  // [LOCALE DATASET]
  // Danh sách tên giả mang tính địa phương (Vietnamese Context).
  // Việc dùng tên giả có format giống tên thật giúp AI xử lý ngữ pháp tự nhiên hơn
  // so với việc dùng mã định danh như "PERSON_1".
  final List<String> _fakeNames = [
    'Nguyễn Văn Đông', 'Trần Thị Trang', 'Lê Văn Cường', 'Phạm Thị Dương',
    'Hoàng Văn Em', 'Phan Thị Phương', 'Vũ Văn Giang', 'Đặng Thị Hạnh',
    'Bùi Văn Hùng', 'Đỗ Thị Kim', 'Hồ Văn Long', 'Ngô Thị Mai',
  ];

  /// ==========================================================================
  /// MAIN ENTRY POINT
  /// ==========================================================================
  /// Thực hiện quy trình ẩn danh hóa toàn bộ email.
  ///
  /// @param subject Tiêu đề email gốc.
  /// @param body Nội dung email gốc.
  /// @param from Địa chỉ người gửi gốc.
  /// @return Map chứa dữ liệu đã làm sạch và metadata phục vụ thống kê.
  Map<String, dynamic> anonymizeEmail({
    required String subject,
    required String body,
    required String from,
  }) {
    // [PHASE 1]: Preprocessing (Tiền xử lý)
    // Loại bỏ các ký tự rác để Regex hoạt động chính xác hơn.
    final processedSubject = _preprocessText(subject);
    final processedBody = _preprocessText(body);

    // [PHASE 2]: Entity Masking (Làm mờ thực thể)
    // Đây là bước quan trọng nhất, tiêu tốn nhiều CPU nhất.
    final anonymizedSubject = _maskEntities(processedSubject);
    final anonymizedBody = _maskEntities(processedBody);
    
    // [SECURITY DECISION - EXCEPTION]
    // KHÔNG làm mờ địa chỉ người gửi ('from').
    // Lý do: Việc phát hiện Phishing dựa rất nhiều vào Reputation (uy tín)
    // của domain người gửi (VD: support@google.com vs support@g00gle.com).
    // Nếu làm mờ, AI sẽ mất khả năng phát hiện giả mạo thương hiệu.
    final anonymizedFrom = from;

    return {
      'subject': anonymizedSubject,
      'body': anonymizedBody,
      'from': anonymizedFrom,
      'mapping': _getMappingInfo(), // Trả về map để (nếu cần) có thể khôi phục cục bộ
      'entityCount': _getEntityCount(), // Metadata cho Dashboard thống kê
    };
  }

  /// ==========================================================================
  /// TEXT NORMALIZATION ENGINE
  /// ==========================================================================
  /// Chuẩn hóa văn bản đầu vào để tránh các cuộc tấn công dạng "Invisible Characters"
  /// hoặc làm nhiễu Regex.
  String _preprocessText(String text) {
    // 1. Collapse Whitespace: Biến nhiều dấu cách/tab thành 1 dấu cách.
    // Giúp giảm token gửi lên AI.
    String processed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // 2. Normalize Newlines: Thống nhất chuẩn xuống dòng về \n (Unix style).
    processed = processed.replaceAll('\r\n', '\n');
    processed = processed.replaceAll('\r', '\n');
    
    // 3. Sanitize Control Characters:
    // Loại bỏ các ký tự điều khiển ASCII không in được (trừ \n, \t).
    // Hacker có thể dùng các ký tự này để thực hiện Prompt Injection.
    processed = processed.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    
    return processed;
  }

  /// ==========================================================================
  /// CORE MASKING ALGORITHM (REGEX-BASED NER)
  /// ==========================================================================
  /// Quét và thay thế các thực thể nhạy cảm.
  ///
  /// [Algorithm Strategy]:
  /// 1. Scan: Chạy tất cả Regex để tìm vị trí (Start, End) của các thực thể.
  /// 2. Collect: Lưu vào danh sách `matches`.
  /// 3. Sort: Sắp xếp danh sách theo vị trí GIẢM DẦN (từ cuối lên đầu).
  /// 4. Replace: Thay thế text dựa trên danh sách đã sắp xếp.
  ///    -> Tại sao phải Reverse Sort? Để việc thay thế một từ ở cuối văn bản
  ///       không làm thay đổi chỉ mục (index) của các từ ở đầu văn bản.
  String _maskEntities(String text) {
    final List<EntityMatch> matches = [];

    // --- DETECTOR 1: EMAIL ADDRESS ---
    // Chuẩn RFC 5322 (simplified)
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
      caseSensitive: false,
    );
    for (var match in emailRegex.allMatches(text)) {
      matches.add(EntityMatch(
        start: match.start,
        end: match.end,
        original: match.group(0)!,
        type: 'EMAIL',
      ));
    }

    // --- DETECTOR 2: PHONE NUMBERS ---
    // Hỗ trợ đầu số Việt Nam (+84, 0...) và các định dạng dấu phân cách (., -, space)
    final phoneRegex = RegExp(
      r'(?:\+84|0)(?:\d{9,10})|(?:\(\d{2,4}\)\s?\d{6,8})|(?:\d{2,4}[-.\s]?\d{3,4}[-.\s]?\d{3,4})',
    );
    for (var match in phoneRegex.allMatches(text)) {
      matches.add(EntityMatch(
        start: match.start,
        end: match.end,
        original: match.group(0)!,
        type: 'PHONE',
      ));
    }

    // --- DETECTOR 3: URLS ---
    // Phát hiện link http/https để tránh AI click nhầm vào link độc hại
    // hoặc lộ token trên URL.
    final urlRegex = RegExp(
      r'https?://[^\s<>"]+|www\.[^\s<>"]+',
      caseSensitive: false,
    );
    for (var match in urlRegex.allMatches(text)) {
      matches.add(EntityMatch(
        start: match.start,
        end: match.end,
        original: match.group(0)!,
        type: 'URL',
      ));
    }

    // --- DETECTOR 4: NATIONAL ID (CCCD/CMND) ---
    // Detect chuỗi số 9 hoặc 12 ký tự liền nhau (Pattern matching cơ bản).
    // Cần cẩn trọng với False Positive (nhầm với số tiền).
    final idRegex = RegExp(
      r'\b(?:\d{9}|\d{12})\b',
    );
    for (var match in idRegex.allMatches(text)) {
      final id = match.group(0)!;
      // Validation Logic: Độ dài cứng
      if (id.length == 9 || id.length == 12) {
        matches.add(EntityMatch(
          start: match.start,
          end: match.end,
          original: id,
          type: 'ID',
        ));
      }
    }

    // --- DETECTOR 5: DATES ---
    // Định dạng ngày tháng phổ biến tại VN (DD/MM/YYYY hoặc YYYY/MM/DD)
    final dateRegex = RegExp(
      r'\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{2,4}[/-]\d{1,2}[/-]\d{1,2})',
    );
    for (var match in dateRegex.allMatches(text)) {
      matches.add(EntityMatch(
        start: match.start,
        end: match.end,
        original: match.group(0)!,
        type: 'DATE',
      ));
    }

    // --- DETECTOR 6: PERSON NAMES (HEURISTIC) ---
    // Phát hiện dựa trên quy tắc viết hoa: 2-4 từ liên tiếp bắt đầu bằng chữ hoa.
    // [LIMITATION]: Có thể nhầm lẫn với tên Công ty hoặc đầu câu.
    // Regex hỗ trợ Unicode Tiếng Việt (ÀÁẠ...).
    final nameRegex = RegExp(
      r'\b(?:[A-ZÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ][a-zàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]+\s){1,3}[A-ZÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ][a-zàáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]+',
    );
    for (var match in nameRegex.allMatches(text)) {
      final name = match.group(0)!;
      final words = name.split(' ');
      // Logic lọc thêm: Tên người thường từ 2-4 từ.
      if (words.length >= 2 && words.length <= 4) {
        matches.add(EntityMatch(
          start: match.start,
          end: match.end,
          original: name,
          type: 'PERSON',
        ));
      }
    }

    // --- DETECTOR 7: LOCATIONS ---
    // Danh sách cứng (Hard-coded) các địa danh phổ biến và pattern "Quận/Huyện".
    final locationRegex = RegExp(
      r'\b(?:Hà Nội|TP\.?\s*HCM|Sài Gòn|Đà Nẵng|Hải Phòng|Cần Thơ|' +
      r'Quận \d+|Phường [^\s,]+|Đường [^\s,]+|' +
      r'Tỉnh [^\s,]+|Thành phố [^\s,]+)',
      caseSensitive: false,
    );
    for (var match in locationRegex.allMatches(text)) {
      matches.add(EntityMatch(
        start: match.start,
        end: match.end,
        original: match.group(0)!,
        type: 'LOCATION',
      ));
    }

    // [CRITICAL STEP]
    // Sắp xếp matches từ cuối lên đầu.
    // Nếu thay thế từ đầu ('a' tại index 5), chuỗi sẽ ngắn đi hoặc dài ra,
    // làm sai lệch index của 'b' tại index 20.
    matches.sort((a, b) => b.start.compareTo(a.start));

    // Thực hiện replace trên chuỗi gốc
    String maskedText = text;
    for (var match in matches) {
      // Lấy giá trị thay thế (có cache)
      final replacement = _getReplacementForEntity(match.original, match.type);
      
      // Cắt chuỗi và ghép giá trị mới vào
      maskedText = maskedText.substring(0, match.start) + 
                   replacement + 
                   maskedText.substring(match.end);
    }

    return maskedText;
  }

  /// ==========================================================================
  /// REPLACEMENT STRATEGY & STATE KEEPER
  /// ==========================================================================
  /// Hàm quyết định xem nên dùng lại giá trị cũ hay sinh giá trị mới.
  /// Đảm bảo nguyên tắc: 1 PII gốc = 1 PII giả duy nhất trong phiên.
  String _getReplacementForEntity(String original, String type) {
    switch (type) {
      case 'EMAIL':
        // Check Cache
        if (_emailMapping.containsKey(original)) {
          return _emailMapping[original]!;
        }
        // Generate New
        final replacement = 'email${_emailCounter}@example.com';
        // Save State
        _emailMapping[original] = replacement;
        _emailCounter++;
        return replacement;

      case 'PHONE':
        if (_phoneMapping.containsKey(original)) {
          return _phoneMapping[original]!;
        }
        // Format giả định 10 số bắt đầu bằng 0
        final replacement = '0${_phoneCounter.toString().padLeft(9, '0')}';
        _phoneMapping[original] = replacement;
        _phoneCounter++;
        return replacement;

      case 'URL':
        if (_urlMapping.containsKey(original)) {
          return _urlMapping[original]!;
        }
        // Defanging URL: Biến link thành text vô hại
        final replacement = 'https://example${_urlCounter}.com';
        _urlMapping[original] = replacement;
        _urlCounter++;
        return replacement;

      case 'ID':
        if (_idMapping.containsKey(original)) {
          return _idMapping[original]!;
        }
        // Giữ nguyên độ dài (Length Preserving) để tránh phá vỡ layout
        final length = original.length;
        final replacement = _idCounter.toString().padLeft(length, '0');
        _idMapping[original] = replacement;
        _idCounter++;
        return replacement;

      case 'DATE':
        if (_dateMapping.containsKey(original)) {
          return _dateMapping[original]!;
        }
        // Thay bằng placeholder chung chung
        final replacement = 'DD/MM/YYYY';
        _dateMapping[original] = replacement;
        _dateCounter++;
        return replacement;

      case 'PERSON':
        if (_personMapping.containsKey(original)) {
          return _personMapping[original]!;
        }
        // Ưu tiên lấy tên từ danh sách Fake Names để tạo cảm giác tự nhiên cho AI
        final replacement = _personCounter <= _fakeNames.length
            ? _fakeNames[_personCounter - 1]
            : 'Người ${_personCounter}'; // Fallback nếu hết tên trong kho
        _personMapping[original] = replacement;
        _personCounter++;
        return replacement;

      case 'LOCATION':
        if (_locationMapping.containsKey(original)) {
          return _locationMapping[original]!;
        }
        final replacement = 'Địa điểm ${_locationCounter}';
        _locationMapping[original] = replacement;
        _locationCounter++;
        return replacement;

      default:
        return original;
    }
  }

  // --- Utility Methods: Export Data & Stats ---

  Map<String, Map<String, String>> _getMappingInfo() {
    return {
      'person': Map.from(_personMapping),
      'phone': Map.from(_phoneMapping),
      'email': Map.from(_emailMapping),
      'location': Map.from(_locationMapping),
      'id': Map.from(_idMapping),
      'url': Map.from(_urlMapping),
      'date': Map.from(_dateMapping),
    };
  }

  Map<String, int> _getEntityCount() {
    return {
      'person': _personMapping.length,
      'phone': _phoneMapping.length,
      'email': _emailMapping.length,
      'location': _locationMapping.length,
      'id': _idMapping.length,
      'url': _urlMapping.length,
      'date': _dateMapping.length,
    };
  }

  /// Reset trạng thái khi bắt đầu phiên quét mới
  void reset() {
    _personMapping.clear();
    _phoneMapping.clear();
    _emailMapping.clear();
    _locationMapping.clear();
    _idMapping.clear();
    _urlMapping.clear();
    _dateMapping.clear();
    
    _personCounter = 1;
    _phoneCounter = 1;
    _emailCounter = 1;
    _locationCounter = 1;
    _idCounter = 1;
    _urlCounter = 1;
    _dateCounter = 1;
  }
}

/// DTO (Data Transfer Object) để lưu trữ thông tin về thực thể tìm thấy
class EntityMatch {
  final int start;      // Vị trí bắt đầu trong chuỗi gốc
  final int end;        // Vị trí kết thúc
  final String original; // Giá trị gốc (VD: "0909123456")
  final String type;     // Loại thực thể (EMAIL, PHONE,...)

  EntityMatch({
    required this.start,
    required this.end,
    required this.original,
    required this.type,
  });
}