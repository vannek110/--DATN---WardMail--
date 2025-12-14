#!/usr/bin/env python3
"""
Script to integrate EmailSafetyWidget into email_detail_screen.dart
"""

import re

def integrate_safety_widget():
    file_path = r'd:\DATN\DATN---GuardMail\lib\screens\email_detail_screen.dart'
    
    # Read the file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Step 1: Add import
    if '../widgets/email_safety_widget.dart' not in content:
        import_pattern = r"(import '../widgets/email_feedback_widget.dart';)"
        import_replacement = r"\1\nimport '../widgets/email_safety_widget.dart';"
        content = re.sub(import_pattern, import_replacement, content)
        print("✅ Added import for EmailSafetyWidget")
    
    # Step 2: Add widget after _buildAnalysisResult() and before EmailFeedbackWidget
    # Find the pattern
    pattern = r'(if \(_scanResult != null\) \.\.\.\[\s+_buildAnalysisResult\(\),)'
    replacement = r'''\1
              EmailSafetyWidget(
                emailSubject: widget.email.subject,
                emailBody: widget.email.body ?? '',
              ),'''
    
    if 'EmailSafetyWidget(' not in content:
        content = re.sub(pattern, replacement, content)
        print("✅ Added EmailSafetyWidget to body")
    else:
        print("ℹ️  Widget already exists")
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("\n🎉 Integration complete!")
    print("Safety widget will appear after analysis result!")

if __name__ == '__main__':
    try:
        integrate_safety_widget()
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
