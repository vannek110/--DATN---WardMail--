import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/feedback_service.dart';
import '../localization/app_localizations.dart';

class EmailFeedbackWidget extends StatefulWidget {
  final String emailId;
  final Function() onReanalyze;

  const EmailFeedbackWidget({
    super.key,
    required this.emailId,
    required this.onReanalyze,
  });

  @override
  State<EmailFeedbackWidget> createState() => _EmailFeedbackWidgetState();
}

class _EmailFeedbackWidgetState extends State<EmailFeedbackWidget> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _feedbackController = TextEditingController();
  List<Map<String, dynamic>> _feedbackHistory = [];
  bool _isReanalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadFeedbackHistory();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbackHistory() async {
    final history = await _feedbackService.getFeedbackForEmail(widget.emailId);
    if (mounted) {
      setState(() {
        _feedbackHistory = history;
      });
    }
  }

  Future<void> _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.t('feedback_empty_message')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _feedbackService.saveFeedback(
      emailId: widget.emailId,
      feedback: feedback,
      analysisResult: 'pending',
    );

    _feedbackController.clear();
    await _loadFeedbackHistory();

    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.t('feedback_submitted')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _reanalyzeEmail() async {
    setState(() => _isReanalyzing = true);

    try {
      await widget.onReanalyze();

      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.t('email_detail_analysis_done')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isReanalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50.withOpacity(isDark ? 0.1 : 1),
            Colors.purple.shade50.withOpacity(isDark ? 0.1 : 1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.feedback_outlined,
                color: Colors.blue.shade700.withOpacity(isDark ? 0.8 : 1),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l.t('feedback_section_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l.t('feedback_reanalyze_button'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feedback Input
          Text(
            l.t('feedback_input_hint'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(
              left: 12,
              right: 4,
              top: 4,
              bottom: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.1 : 1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: l.t('feedback_input_hint'),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isReanalyzing ? null : _reanalyzeEmail,
                  icon: _isReanalyzing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(
                    _isReanalyzing
                        ? l.t('feedback_reanalyzing')
                        : l.t('feedback_reanalyze_button'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitFeedback,
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(l.t('feedback_submit_button')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Feedback History
          if (_feedbackHistory.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l.t('feedback_history_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._feedbackHistory.map((item) => _buildFeedbackItem(item, l)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(Map<String, dynamic> item, AppLocalizations l) {
    final timestamp = DateTime.parse(item['timestamp'] as String);
    final feedback = item['feedback'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF1877F2),
                child: Text(
                  'Y',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.t('feedback_you'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(feedback, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
