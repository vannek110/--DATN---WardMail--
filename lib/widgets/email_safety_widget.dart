import 'package:flutter/material.dart';
import '../services/email_safety_checker.dart';
import '../localization/app_localizations.dart';

class EmailSafetyWidget extends StatelessWidget {
  final String emailSubject;
  final String emailBody;

  const EmailSafetyWidget({
    super.key,
    required this.emailSubject,
    required this.emailBody,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    final result = EmailSafetyChecker.check(
      subject: emailSubject,
      body: emailBody,
      locale: locale,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine overall status color
    Color overallColor;
    String overallText;
    IconData overallIcon;

    switch (result.overallStatus) {
      case 'safe':
        overallColor = const Color(0xFF34A853);
        overallText = locale == 'vi' ? 'AN TOÀN ĐỂ GỬI' : 'SAFE TO SEND';
        overallIcon = Icons.check_circle;
        break;
      case 'warning':
        overallColor = const Color(0xFFFBBC04);
        overallText = locale == 'vi' ? 'CẦN XEM XÉT' : 'NEEDS REVIEW';
        overallIcon = Icons.warning_amber;
        break;
      default:
        overallColor = const Color(0xFFEA4335);
        overallText = locale == 'vi' ? 'KHÔNG AN TOÀN' : 'UNSAFE';
        overallIcon = Icons.dangerous;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: overallColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: overallColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(isDark ? 0.1 : 1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  locale == 'vi'
                      ? 'Kiểm tra An toàn Email'
                      : 'Email Safety Check',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Criteria List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCriterionItem(
                  context,
                  title: locale == 'vi' ? 'Bảo vệ PII' : 'PII Protection',
                  passed: result.piiProtection,
                  message: result.piiMessage,
                  details: result.piiDetails,
                  locale: locale,
                ),
                const SizedBox(height: 12),
                _buildCriterionItem(
                  context,
                  title: locale == 'vi' ? 'Chống Lừa đảo' : 'Anti-Phishing',
                  passed: result.antiPhishing,
                  message: result.phishingMessage,
                  details: result.phishingDetails,
                  locale: locale,
                ),
                const SizedBox(height: 12),
                _buildCriterionItem(
                  context,
                  title: locale == 'vi'
                      ? 'Độ chính xác'
                      : 'Information Accuracy',
                  passed: result.informationAccuracy,
                  message: result.accuracyMessage,
                  details: result.accuracyDetails,
                  locale: locale,
                ),
                const SizedBox(height: 12),
                _buildCriterionItem(
                  context,
                  title: locale == 'vi' ? 'Văn phong' : 'Professional Tone',
                  passed: result.professionalTone,
                  message: result.toneMessage,
                  details: result.toneDetails,
                  locale: locale,
                ),
                const SizedBox(height: 12),
                _buildCriterionItem(
                  context,
                  title: locale == 'vi' ? 'Tuân thủ' : 'Compliance',
                  passed: result.compliance,
                  message: result.complianceMessage,
                  details: result.complianceDetails,
                  locale: locale,
                ),
              ],
            ),
          ),

          // Overall Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: overallColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(overallIcon, color: overallColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale == 'vi' ? 'Tổng quan' : 'Overall',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overallText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: overallColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: overallColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${result.passedCount}/5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionItem(
    BuildContext context, {
    required String title,
    required bool passed,
    required String message,
    required List<String> details,
    required String locale,
  }) {
    final statusColor = passed
        ? const Color(0xFF34A853)
        : const Color(0xFFEA4335);
    final statusText = passed
        ? (locale == 'vi' ? 'ĐẠT' : 'PASS')
        : (locale == 'vi' ? 'KHÔNG ĐẠT' : 'FAIL');
    final statusIcon = passed ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('→ ', style: TextStyle(color: statusColor, fontSize: 14)),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(color: statusColor, fontSize: 14),
                    ),
                    Expanded(
                      child: Text(
                        detail,
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
