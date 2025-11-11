import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_result.dart';

class ExportService {
  Future<String> exportToPdf(Map<String, dynamic> statistics, List<ScanResult> scanResults) async {
    final pdf = pw.Document();
    
    final totalScanned = statistics['totalScanned'] ?? 0;
    final phishingCount = statistics['phishingCount'] ?? 0;
    final suspiciousCount = statistics['suspiciousCount'] ?? 0;
    final safeCount = statistics['safeCount'] ?? 0;
    final phishingPercentage = statistics['phishingPercentage'] ?? 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'GuardMail - Báo cáo phát hiện Phishing',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          pw.Text(
            'Tổng quan',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _buildPdfStatRow('Tổng số email đã kiểm tra:', '$totalScanned'),
                pw.SizedBox(height: 8),
                _buildPdfStatRow('Email nguy hiểm:', '$phishingCount', PdfColors.red700),
                pw.SizedBox(height: 8),
                _buildPdfStatRow('Email nghi ngờ:', '$suspiciousCount', PdfColors.orange700),
                pw.SizedBox(height: 8),
                _buildPdfStatRow('Email an toàn:', '$safeCount', PdfColors.green700),
                pw.SizedBox(height: 8),
                _buildPdfStatRow('Tỷ lệ phishing:', '${phishingPercentage.toStringAsFixed(1)}%', PdfColors.red700),
              ],
            ),
          ),
          
          pw.SizedBox(height: 24),
          pw.Text(
            'Chi tiết email được kiểm tra',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildPdfTableCell('Ngày', isHeader: true),
                  _buildPdfTableCell('Người gửi', isHeader: true),
                  _buildPdfTableCell('Tiêu đề', isHeader: true),
                  _buildPdfTableCell('Kết quả', isHeader: true),
                  _buildPdfTableCell('Độ tin cậy', isHeader: true),
                ],
              ),
              ...scanResults.take(50).map((scan) {
                PdfColor statusColor;
                String statusText;
                
                if (scan.isPhishing) {
                  statusColor = PdfColors.red700;
                  statusText = 'Nguy hiểm';
                } else if (scan.isSuspicious) {
                  statusColor = PdfColors.orange700;
                  statusText = 'Nghi ngờ';
                } else {
                  statusColor = PdfColors.green700;
                  statusText = 'An toàn';
                }
                
                return pw.TableRow(
                  children: [
                    _buildPdfTableCell(DateFormat('dd/MM/yy').format(scan.scanDate)),
                    _buildPdfTableCell(scan.from, maxLines: 1),
                    _buildPdfTableCell(scan.subject, maxLines: 2),
                    _buildPdfTableCell(statusText, color: statusColor),
                    _buildPdfTableCell('${(scan.confidenceScore * 100).toInt()}%'),
                  ],
                );
              }),
            ],
          ),
          
          if (scanResults.length > 50)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                'Hiển thị 50/${scanResults.length} email. Xuất CSV để xem đầy đủ.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ),
          
          pw.SizedBox(height: 24),
          pw.Text(
            'Khuyến nghị bảo mật',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          _buildPdfBullet('Luôn kiểm tra địa chỉ email người gửi trước khi mở email'),
          _buildPdfBullet('Không nhấp vào liên kết lạ hoặc đính kèm từ người lạ'),
          _buildPdfBullet('Cảnh giác với email yêu cầu thông tin cá nhân hoặc tài chính'),
          _buildPdfBullet('Bật xác thực hai yếu tố cho các tài khoản quan trọng'),
          _buildPdfBullet('Cập nhật phần mềm và trình duyệt thường xuyên'),
          
          pw.SizedBox(height: 32),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            '© GuardMail - Hệ thống phát hiện phishing email',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory.path}/guardmail_report_$timestamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    
    return path;
  }

  pw.Widget _buildPdfStatRow(String label, String value, [PdfColor? color]) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false, int maxLines = 3, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        maxLines: maxLines,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  pw.Widget _buildPdfBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 4, right: 8),
            width: 4,
            height: 4,
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue700,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> exportToCsv(List<ScanResult> scanResults) async {
    final List<List<dynamic>> rows = [
      ['Ngày', 'Người gửi', 'Tiêu đề', 'Kết quả', 'Độ tin cậy', 'Mối đe dọa'],
    ];

    for (var scan in scanResults) {
      rows.add([
        DateFormat('dd/MM/yyyy HH:mm').format(scan.scanDate),
        scan.from,
        scan.subject,
        scan.result,
        '${(scan.confidenceScore * 100).toInt()}%',
        scan.detectedThreats.join('; '),
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final path = '${directory.path}/guardmail_report_$timestamp.csv';
    final file = File(path);
    await file.writeAsString(csv);
    
    return path;
  }

  Future<void> shareFile(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }
}
