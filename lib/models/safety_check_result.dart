class SafetyCheckResult {
  final bool piiProtection;
  final bool antiPhishing;
  final bool informationAccuracy;
  final bool professionalTone;
  final bool compliance;

  final String piiMessage;
  final String phishingMessage;
  final String accuracyMessage;
  final String toneMessage;
  final String complianceMessage;

  final List<String> piiDetails;
  final List<String> phishingDetails;
  final List<String> accuracyDetails;
  final List<String> toneDetails;
  final List<String> complianceDetails;

  SafetyCheckResult({
    required this.piiProtection,
    required this.antiPhishing,
    required this.informationAccuracy,
    required this.professionalTone,
    required this.compliance,
    required this.piiMessage,
    required this.phishingMessage,
    required this.accuracyMessage,
    required this.toneMessage,
    required this.complianceMessage,
    this.piiDetails = const [],
    this.phishingDetails = const [],
    this.accuracyDetails = const [],
    this.toneDetails = const [],
    this.complianceDetails = const [],
  });

  /// Returns true if all 5 criteria pass
  bool get isAllSafe =>
      piiProtection &&
      antiPhishing &&
      informationAccuracy &&
      professionalTone &&
      compliance;

  /// Returns number of criteria that passed (0-5)
  int get passedCount {
    int count = 0;
    if (piiProtection) count++;
    if (antiPhishing) count++;
    if (informationAccuracy) count++;
    if (professionalTone) count++;
    if (compliance) count++;
    return count;
  }

  /// Returns overall safety level: safe, warning, unsafe
  String get overallStatus {
    if (isAllSafe) return 'safe';
    if (passedCount >= 3) return 'warning';
    return 'unsafe';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'piiProtection': piiProtection,
    'antiPhishing': antiPhishing,
    'informationAccuracy': informationAccuracy,
    'professionalTone': professionalTone,
    'compliance': compliance,
    'piiMessage': piiMessage,
    'phishingMessage': phishingMessage,
    'accuracyMessage': accuracyMessage,
    'toneMessage': toneMessage,
    'complianceMessage': complianceMessage,
    'piiDetails': piiDetails,
    'phishingDetails': phishingDetails,
    'accuracyDetails': accuracyDetails,
    'toneDetails': toneDetails,
    'complianceDetails': complianceDetails,
    'passedCount': passedCount,
    'overallStatus': overallStatus,
  };

  /// Create from JSON
  factory SafetyCheckResult.fromJson(Map<String, dynamic> json) {
    return SafetyCheckResult(
      piiProtection: json['piiProtection'] as bool,
      antiPhishing: json['antiPhishing'] as bool,
      informationAccuracy: json['informationAccuracy'] as bool,
      professionalTone: json['professionalTone'] as bool,
      compliance: json['compliance'] as bool,
      piiMessage: json['piiMessage'] as String,
      phishingMessage: json['phishingMessage'] as String,
      accuracyMessage: json['accuracyMessage'] as String,
      toneMessage: json['toneMessage'] as String,
      complianceMessage: json['complianceMessage'] as String,
      piiDetails: List<String>.from(json['piiDetails'] ?? []),
      phishingDetails: List<String>.from(json['phishingDetails'] ?? []),
      accuracyDetails: List<String>.from(json['accuracyDetails'] ?? []),
      toneDetails: List<String>.from(json['toneDetails'] ?? []),
      complianceDetails: List<String>.from(json['complianceDetails'] ?? []),
    );
  }
}
