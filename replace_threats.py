#!/usr/bin/env python3
"""
Script to replace Detected Threats section with EmailSafetyWidget
"""

import re

def replace_threats_with_safety():
    file_path = r'd:\DATN\DATN---GuardMail\lib\screens\email_detail_screen.dart'
    
    # Read the file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find and replace the detected threats section with EmailSafetyWidget
    # Pattern: from "if (_scanResult!.detectedThreats.isNotEmpty)" to the end of that section
    pattern = r'''if \(_scanResult!\.detectedThreats\.isNotEmpty\) \.\.\.\[
\s+const SizedBox\(height: 16\),
\s+Text\(
\s+l\.t\('email_detail_detected_threats'\),
\s+style: const TextStyle\(
\s+fontSize: 15,
\s+fontWeight: FontWeight\.bold,
\s+\),
\s+\),
\s+const SizedBox\(height: 8\),
\s+Wrap\(
\s+spacing: 8,
\s+runSpacing: 8,
\s+children: _scanResult!\.detectedThreats\.map\(\(threat\) =>[^}]+\}\.toList\(\),
\s+\),
\s+\],'''
    
    replacement = '''// Safety Check Widget (replaces detected threats)
            const SizedBox(height: 16),
            EmailSafetyWidget(
              emailSubject: widget.email.subject,
              emailBody: widget.email.body ?? '',
            ),'''
    
    # Try to replace
    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    if new_content != content:
        # Write back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("✅ Replaced Detected Threats with EmailSafetyWidget")
        print("🎉 Safety widget now appears inside analysis result!")
    else:
        print("ℹ️  Pattern not found, trying alternative approach...")
        
        # Alternative: Just add safety widget and comment out threats
        if 'email_detail_detected_threats' in content:
            # Comment out the threats section
            content = content.replace(
                "if (_scanResult!.detectedThreats.isNotEmpty) ...[",
                "// Replaced with EmailSafetyWidget\n          if (false) ...["
            )
            
            # Add safety widget before the threats section
            content = content.replace(
                "// Replaced with EmailSafetyWidget",
                '''// Email Safety Check
          const SizedBox(height: 16),
          EmailSafetyWidget(
            emailSubject: widget.email.subject,
            emailBody: widget.email.body ?? '',
          ),
          // Replaced with EmailSafetyWidget (old threats section below)'''
            )
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print("✅ Added EmailSafetyWidget and disabled threats section")
            print("🎉 Safety widget now appears in analysis result!")

if __name__ == '__main__':
    try:
        replace_threats_with_safety()
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
