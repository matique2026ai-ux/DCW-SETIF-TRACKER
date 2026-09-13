import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfReportService {
  /// Generate and preview/print official daily attendance & inspection PDF report for ALL employees
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

    // Load fonts for Arabic support
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
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              children: [
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
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        height: 1.5,
                        width: 320,
                        color: PdfColors.amber800,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
              ],
            );
          }
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'محضر المتابعة والرقابة اليومية — مديرية التجارة سطيف',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                ),
                pw.Text(
                  'التاريخ: $dateStr',
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'منظومة المراقبة والتفتيش الميداني الرقمية (DCW-SETIF-TRACKER)',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Report Title Box
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
                    style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                  ),
                  pw.Text(
                    'التاريخ: $dateStr | الساعة: $timeStr',
                    style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Key Statistics Summary Cards
            pw.Row(
              children: [
                _buildPdfStatBox('إجمالي الموظفين', '${employees.length}', PdfColors.blueGrey800),
                pw.SizedBox(width: 6),
                _buildPdfStatBox('حاضرون في الميدان', '${presentEmployees.length}', PdfColors.green800),
                pw.SizedBox(width: 6),
                _buildPdfStatBox('غائبون عن التسجيل', '${absentEmployees.length}', PdfColors.red800),
                pw.SizedBox(width: 6),
                _buildPdfStatBox('معاينات تجارية', '${visits.length}', PdfColors.indigo800),
              ],
            ),
            pw.SizedBox(height: 14),

            // Section 1: Present Inspectors
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border(right: pw.BorderSide(color: PdfColors.green700, width: 3)),
              ),
              child: pw.Text(
                '1. قائمة المفتشين الحاضرين في الميدان اليوم (${presentEmployees.length})',
                style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
              ),
            ),
            pw.SizedBox(height: 6),
            presentEmployees.isEmpty
                ? pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                    child: pw.Center(child: pw.Text('لا يوجد حضور مسجل بعد لهذا اليوم', style: const pw.TextStyle(fontSize: 9.5))),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(28),
                      1: pw.FlexColumnWidth(3.0),
                      2: pw.FlexColumnWidth(3.5),
                      3: pw.FlexColumnWidth(2.0),
                      4: pw.FlexColumnWidth(1.8),
                    },
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
                        final name = emp['NomAr'] != null && emp['NomAr'].toString().trim().isNotEmpty
                            ? '${emp['NomAr']} ${emp['PrenomAr'] ?? ""}'.trim()
                            : '${emp['Nom'] ?? ""} ${emp['Prenom'] ?? ""}'.trim();
                        final service = (emp['Service'] ?? '').toString();
                        final att = attendance.firstWhere((a) => a['EmployeeId'] == emp['Id'], orElse: () => {});
                        final checkInTime = att['CheckInTime'] != null
                            ? att['CheckInTime'].toString().split('T').last.split('.').first
                            : '--:--';
                        final empVisits = visits.where((v) => v['employee_id'] == emp['Id'] || v['EmployeeId'] == emp['Id']).length;

                        return pw.TableRow(
                          children: [
                            _tableCell('$i', alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                            _tableCell(name, bold: true),
                            _tableCell(service),
                            _tableCell(checkInTime, alignment: pw.Alignment.center, textAlign: pw.TextAlign.center, color: PdfColors.green900),
                            _tableCell('$empVisits زيارات', alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                          ],
                        );
                      }),
                    ],
                  ),
            pw.SizedBox(height: 14),

            // Section 2: ALL Absent Employees (Full List across pages)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.red50,
                border: pw.Border(right: pw.BorderSide(color: PdfColors.red700, width: 3)),
              ),
              child: pw.Text(
                '2. قائمة الموظفين والمفتشين غير المسجلين اليوم (${absentEmployees.length}) — السجل الشامل',
                style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
              ),
            ),
            pw.SizedBox(height: 6),
            absentEmployees.isEmpty
                ? pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                    child: pw.Center(child: pw.Text('جميع الموظفين سجلوا حضورهم اليوم بنسبة 100%', style: const pw.TextStyle(fontSize: 9.5))),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(28),
                      1: pw.FlexColumnWidth(3.0),
                      2: pw.FlexColumnWidth(4.0),
                      3: pw.FlexColumnWidth(2.8),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _tableHeader('الرقم'),
                          _tableHeader('الاسم واللقب'),
                          _tableHeader('المصلحة الإدارية / الرتبة'),
                          _tableHeader('الوضعية القانونية'),
                        ],
                      ),
                      ...absentEmployees.asMap().entries.map((entry) {
                        final i = entry.key + 1;
                        final emp = entry.value;
                        final name = emp['NomAr'] != null && emp['NomAr'].toString().trim().isNotEmpty
                            ? '${emp['NomAr']} ${emp['PrenomAr'] ?? ""}'.trim()
                            : '${emp['Nom'] ?? ""} ${emp['Prenom'] ?? ""}'.trim();
                        final service = (emp['Service'] ?? '').toString();

                        return pw.TableRow(
                          children: [
                            _tableCell('$i', alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                            _tableCell(name, bold: true),
                            _tableCell(service),
                            _tableCell('غياب غير مسجل (محل استفسار)', color: PdfColors.red700, alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                          ],
                        );
                      }),
                    ],
                  ),
            pw.SizedBox(height: 20),

            // Official Signature Box
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('رئيس مكتب المستخدمين', style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                    pw.Text('(التأشيرة والختم)', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('السيد المدير الولائي للتجارة وضبط السوق', style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 30),
                    pw.Text('(التوقيع والختم الرسمي)', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
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
      name: 'Rapport_Presence_DCW_Setif_$dateStr.pdf',
    );
  }

  static pw.Widget _buildPdfStatBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(4),
          color: PdfColors.white,
        ),
        child: pw.Column(
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool bold = false,
    PdfColor? color,
    pw.Alignment alignment = pw.Alignment.centerRight,
    pw.TextAlign textAlign = pw.TextAlign.right,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: textAlign,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }
}
