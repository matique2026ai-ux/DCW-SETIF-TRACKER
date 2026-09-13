import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfReportService {
  /// Generate and preview/print official daily attendance & inspection PDF report
  static Future<void> generateAndPrintDailyReport({
    required List<Map<String, dynamic>> employees,
    required List<Map<String, dynamic>> attendance,
    required List<Map<String, dynamic>> visits,
    required String directorName,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateStr = DateFormat('yyyy/MM/dd').format(now);
    final timeStr = DateFormat('HH:mm').format(now);

    // Filter present and absent
    final checkedInIds = attendance.map((a) => a['EmployeeId']).toSet();
    final presentEmployees = employees.where((e) => checkedInIds.contains(e['Id'])).toList();
    final absentEmployees = employees.where((e) => !checkedInIds.contains(e['Id'])).toList();

    // Load fonts for Arabic support if available
    pw.Font? arabicFont;
    try {
      final fontData = await rootBundle.load('assets/fonts/Cairo.ttf');
      arabicFont = pw.Font.ttf(fontData);
    } catch (_) {
      try {
        final fontData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
        arabicFont = pw.Font.ttf(fontData);
      } catch (_) {}
    }

    final theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicFont,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // Official Ministerial Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'الجمهورية الجزائرية الديمقراطية الشعبية',
                    style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'وزارة التجارة الداخلية وضبط السوق الوطنية',
                    style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'مديرية التجارة الداخلية وضبط السوق الوطنية لولاية سطيف',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    height: 1.5,
                    width: 320,
                    color: PdfColors.amber800,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Report Title Box
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'محضر المتابعة والرقابة اليومية الميدانية',
                    style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                  ),
                  pw.Text(
                    'التاريخ: $dateStr | الساعة: $timeStr',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Key Statistics Summary Cards
            pw.Row(
              children: [
                _buildPdfStatBox('إجمالي الموظفين', '${employees.length}', PdfColors.blueGrey800),
                pw.SizedBox(width: 8),
                _buildPdfStatBox('حاضرون في الميدان', '${presentEmployees.length}', PdfColors.green800),
                pw.SizedBox(width: 8),
                _buildPdfStatBox('غائبون عن التسجيل', '${absentEmployees.length}', PdfColors.red800),
                pw.SizedBox(width: 8),
                _buildPdfStatBox('معاينات تجارية', '${visits.length}', PdfColors.indigo800),
              ],
            ),
            pw.SizedBox(height: 18),

            // Section 1: Present Inspectors
            pw.Text(
              '1. قائمة المفتشين الحاضرين في الميدان اليوم (${presentEmployees.length})',
              style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
            ),
            pw.SizedBox(height: 6),
            presentEmployees.isEmpty
                ? pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                    child: pw.Center(child: pw.Text('لا يوجد حضور مسجل بعد لهذا اليوم', style: const pw.TextStyle(fontSize: 10))),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _tableHeader('الرقم'),
                          _tableHeader('الاسم واللقب'),
                          _tableHeader('المصلحة / الرتبة'),
                          _tableHeader('وقت الحضور'),
                          _tableHeader('المعاينات'),
                        ],
                      ),
                      ...presentEmployees.asMap().entries.map((entry) {
                        final i = entry.key + 1;
                        final emp = entry.value;
                        final name = emp['NomAr'] != null ? '${emp['NomAr']} ${emp['PrenomAr']}' : '${emp['Nom']} ${emp['Prenom']}';
                        final service = (emp['Service'] ?? '').toString();
                        final att = attendance.firstWhere((a) => a['EmployeeId'] == emp['Id'], orElse: () => {});
                        final checkInTime = att['CheckInTime'] != null ? att['CheckInTime'].toString().split('T').last.split('.').first : '--:--';
                        final empVisits = visits.where((v) => v['employee_id'] == emp['Id'] || v['EmployeeId'] == emp['Id']).length;

                        return pw.TableRow(
                          children: [
                            _tableCell('$i'),
                            _tableCell(name, bold: true),
                            _tableCell(service),
                            _tableCell(checkInTime),
                            _tableCell('$empVisits زيارات'),
                          ],
                        );
                      }),
                    ],
                  ),
            pw.SizedBox(height: 18),

            // Section 2: Absent Employees
            pw.Text(
              '2. قائمة الموظفين والمفتشين غير المسجلين اليوم (${absentEmployees.length})',
              style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableHeader('الرقم'),
                    _tableHeader('الاسم واللقب'),
                    _tableHeader('المصلحة الإدارية'),
                    _tableHeader('الوضعية القانونية'),
                  ],
                ),
                ...absentEmployees.take(40).toList().asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final emp = entry.value;
                  final name = emp['NomAr'] != null ? '${emp['NomAr']} ${emp['PrenomAr']}' : '${emp['Nom']} ${emp['Prenom']}';
                  final service = (emp['Service'] ?? '').toString();

                  return pw.TableRow(
                    children: [
                      _tableCell('$i'),
                      _tableCell(name),
                      _tableCell(service),
                      _tableCell('غياب غير مسجل (محل استفسار)', color: PdfColors.red700),
                    ],
                  );
                }),
              ],
            ),
            if (absentEmployees.length > 40)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text('... ويوجد ${absentEmployees.length - 40} موظفاً إضافياً في السجل الكامل.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ),
            pw.SizedBox(height: 24),

            // Official Signature Box
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('رئيس مكتب المستخدمين', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 35),
                    pw.Text('(التأشيرة والختم)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('السيد المدير الولائي للتجارة وضبط السوق', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 35),
                    pw.Text('(التوقيع والختم الرسمي)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Open printing / PDF preview directly
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Rapport_Presence_DCIRMN_Setif_$dateStr.pdf',
    );
  }

  static pw.Widget _buildPdfStatBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Center(
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
