#!/usr/bin/env python3
"""
Script to move EmailFeedbackWidget inside analysis result conditional
"""

import re

def move_feedback_inside():
    file_path = r'd:\DATN\DATN---GuardMail\lib\screens\email_detail_screen.dart'
    
    # Read the file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Step 1: Add import if not exists
    if '../widgets/email_feedback_widget.dart' not in content:
        import_pattern = r"(import '../localization/app_localizations.dart';)"
        import_replacement = r"\1\nimport '../widgets/email_feedback_widget.dart';"
        content = re.sub(import_pattern, import_replacement, content)
        print("✅ Added import for EmailFeedbackWidget")
    
    # Step 2: Find and replace the body section
    # Pattern to match the current structure
    old_pattern = r'''body: SingleChildScrollView\(\s*child: Column\(\s*children: \[\s*if \(_scanResult != null\) _buildAnalysisResult\(\),\s*_buildEmailContent\(\),'''
    
    # New structure with feedback inside the if block
    new_structure = '''body: SingleChildScrollView(
        child: Column(
          children: [
            if (_scanResult != null) ...[
              _buildAnalysisResult(),
              EmailFeedbackWidget(
                emailId: widget.email.id,
                onReanalyze: _analyzeEmail,
              ),
            ],
            _buildEmailContent(),'''
    
    if 'if (_scanResult != null) ...[' not in content:
        content = re.sub(old_pattern, new_structure, content, flags=re.DOTALL)
        print("✅ Moved EmailFeedbackWidget inside analysis result conditional")
    else:
        print("ℹ️  Widget already inside conditional")
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("\n🎉 Widget moved successfully!")
    print("Feedback will now only appear when there's an analysis result!")

if __name__ == '__main__':
    try:
        move_feedback_inside()
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
