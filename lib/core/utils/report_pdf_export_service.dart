import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPdfExportService {
  Future<void> exportAdminReports({
    required List<RoadIssueReport> reports,
  }) async {
    final bytes = await _buildPdfBytes(reports: reports);
    await Printing.layoutPdf(
      name: 'nagah_reports_export.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<Uint8List> _buildPdfBytes({
    required List<RoadIssueReport> reports,
  }) async {
    final document = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
    final sortedReports = [...reports]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final tableHeaders = [
      'Priority',
      'Suggested action',
      'Issue type',
      'Location point',
      'Period',
      'Status',
      'Reported at',
    ];

    final tableRows = sortedReports.map((report) {
      return [
        _priorityLabel(report),
        _actionLabel(report.issueType),
        report.issueType.label,
        _locationLabel(report.location),
        _periodLabel(report.createdAt),
        report.status.label,
        dateFormat.format(report.createdAt.toLocal()),
      ];
    }).toList();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(20),
              gradient: const pw.LinearGradient(
                colors: [
                  PdfColor.fromInt(0xFF2B1D16),
                  PdfColor.fromInt(0xFFF97316),
                ],
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NAGAH Road Safety Report',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Intervention criteria table based on the reports currently available in the system.',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _summaryCard(
                title: 'Total reports',
                value: '${reports.length}',
                color: const PdfColor.fromInt(0xFFF97316),
              ),
              pw.SizedBox(width: 10),
              _summaryCard(
                title: 'Approved',
                value:
                    '${reports.where((r) => r.status == ReportStatus.approved).length}',
                color: const PdfColor.fromInt(0xFF16A34A),
              ),
              pw.SizedBox(width: 10),
              _summaryCard(
                title: 'Pending',
                value:
                    '${reports.where((r) => r.status == ReportStatus.pending).length}',
                color: const PdfColor.fromInt(0xFFF59E0B),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Generated on ${dateFormat.format(now)}',
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF6B7280),
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: tableHeaders,
            data: tableRows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF374151),
            ),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.all(6),
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xFFD1D5DB),
              width: 0.7,
            ),
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF9FAFB),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF3F4F6),
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Text(
              'Day reports are counted from 06:00 AM to 05:59 PM. Night reports are counted from 06:00 PM to 05:59 AM. This export is generated directly from the report submission time and the current reviewed status in the application.',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromInt(0xFF374151),
                lineSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _summaryCard({
    required String title,
    required String value,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF9FAFB),
          borderRadius: pw.BorderRadius.circular(16),
          border: pw.Border.all(color: color, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(
                color: PdfColor.fromInt(0xFF6B7280),
                fontSize: 9,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _locationLabel(LocationPoint location) {
    return '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
  }

  String _periodLabel(DateTime createdAt) {
    final hour = createdAt.toLocal().hour;
    return hour >= 6 && hour < 18 ? 'Day' : 'Night';
  }

  String _priorityLabel(RoadIssueReport report) {
    return switch (report.issueType) {
      IssueType.accident => 'High',
      IssueType.traffic => 'Medium',
      IssueType.pothole => 'Medium',
    };
  }

  String _actionLabel(IssueType issueType) {
    return switch (issueType) {
      IssueType.accident => 'Camera / warning sign',
      IssueType.traffic => 'Signal / lane control',
      IssueType.pothole => 'Road maintenance',
    };
  }
}
