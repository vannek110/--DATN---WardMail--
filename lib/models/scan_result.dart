class ScanResult {
  final String id;
  final String emailId;
  final String from;
  final String subject;
  final DateTime scanDate;
  final String result; // 'safe', 'phishing', 'suspicious'
  final double confidenceScore; // 0.0 to 1.0
  final List<String> detectedThreats;
  final Map<String, dynamic> analysisDetails;

  ScanResult({
    required this.id,
    required this.emailId,
    required this.from,
    required this.subject,
    required this.scanDate,
    required this.result,
    required this.confidenceScore,
    this.detectedThreats = const [],
    this.analysisDetails = const {},
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] ?? '',
      emailId: json['emailId'] ?? '',
      from: json['from'] ?? '',
      subject: json['subject'] ?? '',
      scanDate: json['scanDate'] != null 
          ? DateTime.parse(json['scanDate']) 
          : DateTime.now(),
      result: json['result'] ?? 'safe',
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      detectedThreats: json['detectedThreats'] != null
          ? List<String>.from(json['detectedThreats'])
          : [],
      analysisDetails: json['analysisDetails'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emailId': emailId,
      'from': from,
      'subject': subject,
      'scanDate': scanDate.toIso8601String(),
      'result': result,
      'confidenceScore': confidenceScore,
      'detectedThreats': detectedThreats,
      'analysisDetails': analysisDetails,
    };
  }

  bool get isPhishing => result == 'phishing';
  bool get isSuspicious => result == 'suspicious';
  bool get isSafe => result == 'safe';
}
