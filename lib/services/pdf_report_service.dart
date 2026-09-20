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
    DateTime? reportDate,
  }) async {
    final pdf = pw.Document();

    final now = reportDate ?? DateTime.now();
    final dateStr = DateFormat('yyyy/MM/dd').format(now);
    final timeStr = DateFormat('HH:mm').format(DateTime.now());

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
                      0: pw.FlexColumnWidth(1.8), // Leftmost: المعاينات
                      1: pw.FlexColumnWidth(2.0), // وقت الحضور
                      2: pw.FlexColumnWidth(3.5), // المصلحة / الرتبة
                      3: pw.FlexColumnWidth(3.0), // الاسم واللقب
                      4: pw.FixedColumnWidth(28), // Rightmost: الرقم
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _tableHeader('المعاينات'),
                          _tableHeader('وقت الحضور'),
                          _tableHeader('المصلحة / الرتبة'),
                          _tableHeader('الاسم واللقب'),
                          _tableHeader('الرقم'),
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
                            _tableCell('$empVisits زيارات', alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                            _tableCell(checkInTime, alignment: pw.Alignment.center, textAlign: pw.TextAlign.center, color: PdfColors.green900),
                            _tableCell(service),
                            _tableCell(name, bold: true),
                            _tableCell('$i', alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                          ],
                        );
                      }),
                    ],
                  ),
            pw.SizedBox(height: 14),

            // Section 2: ALL Absent Employees (Full List across pages, ordered from Right to Left)
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
                      0: pw.FlexColumnWidth(2.8), // Leftmost: الوضعية القانونية
                      1: pw.FlexColumnWidth(4.0), // المصلحة الإدارية / الرتبة
                      2: pw.FlexColumnWidth(3.0), // الاسم واللقب
                      3: pw.FixedColumnWidth(28), // Rightmost: الرقم
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _tableHeader('الوضعية القانونية'),
                          _tableHeader('المصلحة الإدارية / الرتبة'),
                          _tableHeader('الاسم واللقب'),
                          _tableHeader('الرقم'),
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
                            _tableCell('غياب غير مسجل (محل استفسار)', color: PdfColors.red700, alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                            _tableCell(service),
                            _tableCell(name, bold: true),
                            _tableCell('$i', alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
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

  /// Generate and print official individual Inquiry Letter (استمارة استفسار إداري كتابي)
  static Future<void> generateAndPrintInquiryLetter(Map<String, dynamic> inquiry) async {
    final pdf = pw.Document();

    final nomAr = inquiry['NomAr'] ?? inquiry['nomar'] ?? inquiry['Nom'] ?? inquiry['nom'] ?? inquiry['name'] ?? inquiry['employeeName'] ?? '';
    final prenomAr = inquiry['PrenomAr'] ?? inquiry['prenomar'] ?? inquiry['Prenom'] ?? inquiry['prenom'] ?? '';
    final name = (nomAr.toString().trim().isNotEmpty || prenomAr.toString().trim().isNotEmpty)
        ? '$nomAr $prenomAr'.trim()
        : (inquiry['EmployeeName'] ?? inquiry['employee_name'] ?? 'عضو فرقة الرقابة والتفتيش').toString();
    final service = (inquiry['Service'] ?? inquiry['service'] ?? 'مديرية التجارة لولاية سطيف').toString();
    final grade = (inquiry['Grade'] ?? inquiry['grade'] ?? 'مفتش رئيسي').toString();
    final rawDate = (inquiry['IncidentDate'] ?? inquiry['incidentdate'] ?? inquiry['Date'] ?? inquiry['date'] ?? inquiry['CreatedAt'] ?? '').toString();
    final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : (rawDate.isNotEmpty ? rawDate : DateFormat('yyyy/MM/dd').format(DateTime.now()));
    final subject = (inquiry['Subject'] ?? inquiry['subject'] ?? 'استفسار كتابي حول الانضباط ومواقيت العمل').toString();
    final details = (inquiry['Details'] ?? inquiry['details'] ??
        'بناءً على السجلات الرسمية للحضور والانصراف عبر المنصة الرقمية، سُجل بحقكم غياب/تأخر عن موعد العمل الميداني دون إشعار مسبق أو رخصة قانونية.').toString();
    final int lateMins = ((inquiry['LateMinutes'] ?? inquiry['lateminutes'] ?? 0) as num).toInt();
    final reply = inquiry['EmployeeReply'] ?? inquiry['employeereply'] ?? inquiry['Reply'] ?? inquiry['reply'];
    final decision = inquiry['DirectorDecision'] ?? inquiry['directordecision'];
    final directorNotes = inquiry['DirectorNotes'] ?? inquiry['directornotes'];
    final inqId = (inquiry['Id'] ?? inquiry['id'] ?? '—').toString();

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
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Official Republic Header
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
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'مصلحة الإدارة والوسائل — مكتب المستخدمين والتكوين',
                      style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(height: 1.2, width: 280, color: PdfColors.black),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

                // Document Reference & Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الرقم: 2026/استفسار/$inqId', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('سطيف في: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 14),

                // Document Title Banner
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Text(
                    'استمـارة استفسـار إداري كتـابي رسمـي',
                    style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 14),

                // Addressed to
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('إلى السيد(ة): ', style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          pw.Text(name, style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('الرتبة: $grade', style: const pw.TextStyle(fontSize: 9.5)),
                          pw.Text('المصلحة/الهيكل: $service', style: const pw.TextStyle(fontSize: 9.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Subject & Legal Reference
                pw.Text('الموضوع: $subject', style: const pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('المرجع: الأمر رقم 06-03 المؤرخ في 15 يوليو 2006 المتضمن القانون الأساسي العام للوظيفة العمومية.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                pw.SizedBox(height: 10),

                // Incident Details
                pw.Text(
                  '$details\n${lateMins > 0 ? "وقد قُدِّر التأخر الفعلي المسجل عن توقيت العمل بـ: $lateMins دقيقة.\n" : ""}',
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
                ),
                pw.SizedBox(height: 4),

                pw.Text(
                  'وعليه، يُطلب منكم موافاة الإدارة ومكتب المستخدمين بتبريراتكم وأسباب ذلك كتابياً في أجل أقصاه 48 ساعة من تاريخ استلامكم هذا الاستفسار، حتى يتسنى للمدير الولائي اتخاذ الإجراءات الإدارية والقانونية المناسبة.',
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
                ),
                pw.SizedBox(height: 12),

                // Reply if exists
                if (reply != null && reply.toString().trim().isNotEmpty) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('رد وتبرير الموظف (المسجل رسمياً):', style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text('$reply', style: const pw.TextStyle(fontSize: 9.5)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Director Decision if exists
                if (decision != null) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.black, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('قرار السيد المدير الولائي للتجارة:', style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          decision == 'justified'
                              ? 'قبول التبرير وحفظ الملف دون أي أثر مالي.'
                              : decision == 'warning'
                                  ? 'توجيه تنبيه/إنذار إداري رسمي يسجل في الملف المهني.'
                                  : 'تثبيت الخصم المالي من الراتب بمقدار: ${inquiry['DeductionDays'] ?? 1} يوم.',
                          style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                        ),
                        if (directorNotes != null && directorNotes.toString().isNotEmpty)
                          pw.Text('الملاحظات: $directorNotes', style: const pw.TextStyle(fontSize: 8.5)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],

                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('تأشيرة رئيس مكتب المستخدمين', style: const pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 35),
                        pw.Text('عـ/ المدير والآمر بالصرف', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('المدير الولائي للتجارة', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 35),
                        pw.Text('ولاية سطيف', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
              ],
            );
          },
        ),
      );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Demande_Explication_${name.replaceAll(' ', '_')}_$dateStr.pdf',
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

  // ──────────────────────────────────────────────────────────────────────────
  // STRATEGIC INSPECTION SUMMARY REPORT — for Director's Decision Making
  // ──────────────────────────────────────────────────────────────────────────
  static Future<void> generateAndPrintInspectionSummaryReport({
    required Map<String, dynamic> reportData,
    required String directorName,
  }) async {
    final pdf = pw.Document();

    final meta = reportData['meta'] as Map<String, dynamic>? ?? {};
    final summary = reportData['summary'] as Map<String, dynamic>? ?? {};
    final inspectorList = (reportData['inspectorBreakdown'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];
    final deptList = (reportData['departmentBreakdown'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];
    final dailyTrend = (reportData['dailyTrend'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];
    final attendanceGPS = (reportData['attendanceGPSArchive'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];

    final periodStart = meta['periodStart']?.toString() ?? '';
    final periodEnd = meta['periodEnd']?.toString() ?? '';
    final daysCount = meta['daysCount']?.toString() ?? '1';
    final dateStr = DateFormat('yyyy/MM/dd').format(DateTime.now());

    final totalVisits = summary['totalVisits'] ?? 0;
    final totalViolations = summary['totalViolations'] ?? 0;
    final violationRate = summary['violationRate'] ?? 0;
    final totalSeizure = summary['totalSeizureValueDZD'] ?? 0;
    final totalApproved = summary['totalApproved'] ?? 0;
    final approvalRate = summary['approvalRate'] ?? 0;
    final totalInspectors = summary['totalInspectors'] ?? 0;

    // Load Arabic font
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
    final theme = pw.ThemeData.withFont(base: arabicFont, bold: arabicFont);

    // Helper: build a header cell
    pw.Widget hCell(String text) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: PdfColors.brown800,
      child: pw.Text(text,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
          textAlign: pw.TextAlign.center),
    );

    // Helper: build a data cell
    pw.Widget dCell(String text, {PdfColor? bg}) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      color: bg ?? PdfColors.white,
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center),
    );

    // ── Page 1: Cover + Summary KPIs
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      build: (context) => [
        // Official header
        pw.Center(
          child: pw.Column(children: [
            pw.Text('الجمهورية الجزائرية الديمقراطية الشعبية',
                style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text('وزارة التجارة الداخلية وضبط السوق الوطنية',
                style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text('مديرية التجارة الداخلية وضبط السوق الوطنية — ولاية سطيف',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 6),
            pw.Container(height: 1.5, width: 300, color: PdfColors.amber800),
          ]),
        ),
        pw.SizedBox(height: 14),

        // Report Title
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.brown50,
              border: pw.Border.all(color: PdfColors.amber800, width: 1),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(children: [
              pw.Text('تقرير الإحصائيات الرقابية الشامل',
                  style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('الفترة: من $periodStart إلى $periodEnd ($daysCount يوم)',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.brown700)),
              pw.SizedBox(height: 2),
              pw.Text('صادر بتاريخ: $dateStr | المدير الولائي: $directorName',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ]),
          ),
        ),
        pw.SizedBox(height: 16),

        // KPI summary grid
        pw.Text('أولاً — المؤشرات العامة للرقابة الميدانية',
            style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.GridView(
          crossAxisCount: 4,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 2.2,
          children: [
            _buildKpiCard('إجمالي المعاينات', '$totalVisits', PdfColors.blue800),
            _buildKpiCard('المخالفات المحررة', '$totalViolations', PdfColors.red800),
            _buildKpiCard('نسبة المخالفات', '$violationRate%', PdfColors.orange800),
            _buildKpiCard('قيمة الحجز (دج)', '${NumberFormat('#,###').format(totalSeizure)}', PdfColors.purple800),
            _buildKpiCard('معاينات مؤشرة', '$totalApproved', PdfColors.green800),
            _buildKpiCard('نسبة التأشير', '$approvalRate%', PdfColors.teal700),
            _buildKpiCard('عدد المفتشين', '$totalInspectors', PdfColors.brown700),
            _buildKpiCard('أيام الفترة', '$daysCount', PdfColors.grey700),
          ],
        ),
        pw.SizedBox(height: 16),

        // Department breakdown table
        if (deptList.isNotEmpty) ...[
          pw.Text('ثانياً — التوزيع حسب المصلحة الرقابية',
              style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(children: [
                hCell('المصلحة'),
                hCell('المعاينات'),
                hCell('المخالفات'),
                hCell('قيمة الحجز (دج)'),
                hCell('مؤشر'),
                hCell('المفتشون'),
              ]),
              ...deptList.map((d) {
                final dept = d['service']?.toString() ?? '';
                final shortDept = dept.length > 30 ? '${dept.substring(0, 28)}...' : dept;
                return pw.TableRow(children: [
                  dCell(shortDept, bg: PdfColors.grey100),
                  dCell('${d['visitsCount'] ?? 0}'),
                  dCell('${d['violationsCount'] ?? 0}'),
                  dCell(NumberFormat('#,###').format(d['seizureValue'] ?? 0)),
                  dCell('${d['approvedCount'] ?? 0}'),
                  dCell('${d['inspectorCount'] ?? 0}'),
                ]);
              }),
            ],
          ),
          pw.SizedBox(height: 14),
        ],

        // Daily trend table
        if (dailyTrend.isNotEmpty) ...[
          pw.Text('ثالثاً — التطور اليومي للمعاينات الميدانية',
              style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(children: [
                hCell('التاريخ'),
                hCell('المعاينات'),
                hCell('المخالفات'),
                hCell('قيمة الحجز (دج)'),
                hCell('مؤشر'),
              ]),
              ...dailyTrend.map((d) => pw.TableRow(children: [
                dCell(d['date']?.toString() ?? '', bg: PdfColors.grey100),
                dCell('${d['visits'] ?? 0}'),
                dCell('${d['violations'] ?? 0}'),
                dCell(NumberFormat('#,###').format(d['seizureValue'] ?? 0)),
                dCell('${d['approved'] ?? 0}'),
              ])),
            ],
          ),
        ],
      ],
    ));

    // ── Page 2: Inspector Ranking + GPS Archive
    if (inspectorList.isNotEmpty || attendanceGPS.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('تقرير الإحصاء الرقابي — مديرية التجارة سطيف',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              pw.Text('الفترة: $periodStart → $periodEnd',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (context) => [
          // Inspector performance ranking
          if (inspectorList.isNotEmpty) ...[
            pw.Text('رابعاً — ترتيب أداء المفتشين الميدانيين',
                style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1.5),
                6: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(children: [
                  hCell('#'),
                  hCell('اسم المفتش'),
                  hCell('المصلحة'),
                  hCell('معاينات'),
                  hCell('مخالفات'),
                  hCell('قيمة الحجز (دج)'),
                  hCell('مؤشر'),
                ]),
                ...inspectorList.asMap().entries.map((entry) {
                  final i = entry.key;
                  final insp = entry.value;
                  final service_ = (insp['service']?.toString() ?? '');
                  final shortSvc = service_.contains('المستهلك') ? 'ق. الغش' :
                      service_.contains('المنافسة') ? 'المنافسة' :
                      service_.contains('الإدارة') ? 'الإدارة' : service_.length > 15 ? '${service_.substring(0, 12)}...' : service_;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: i % 2 == 0 ? PdfColors.white : PdfColors.grey50),
                    children: [
                      dCell('${i + 1}'),
                      dCell(insp['name']?.toString() ?? ''),
                      dCell(shortSvc),
                      dCell('${insp['visitsCount'] ?? 0}'),
                      dCell('${insp['violationsCount'] ?? 0}'),
                      dCell(NumberFormat('#,###').format(insp['totalSeizureValue'] ?? 0)),
                      dCell('${insp['approvedVisits'] ?? 0}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 14),
          ],

          // GPS Attendance Archive
          if (attendanceGPS.isNotEmpty) ...[
            pw.Text('خامساً — أرشيف البصمة الجغرافية للحضور (GPS)',
                style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
              'يوضح هذا الجدول توثيق الحضور بالإحداثيات الجغرافية الدقيقة لكل موظف في الفترة المحددة.',
              style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(children: [
                  hCell('الموظف'),
                  hCell('التاريخ'),
                  hCell('وقت الدخول'),
                  hCell('خط العرض (GPS)'),
                  hCell('خط الطول (GPS)'),
                  hCell('داخل النطاق'),
                ]),
                ...attendanceGPS.take(50).map((a) {
                  final lat = a['checkInLatitude'];
                  final lng = a['checkInLongitude'];
                  final inGeo = a['isWithinGeofence'] == true ? '✓' : '✗';
                  final checkIn = a['checkInTime']?.toString() ?? '';
                  final shortTime = checkIn.length >= 16 ? checkIn.substring(11, 16) : checkIn;
                  return pw.TableRow(children: [
                    dCell(a['name']?.toString() ?? '', bg: PdfColors.grey50),
                    dCell(a['date']?.toString() ?? ''),
                    dCell(shortTime),
                    dCell(lat != null ? (lat as num).toStringAsFixed(5) : 'غير مسجل'),
                    dCell(lng != null ? (lng as num).toStringAsFixed(5) : 'غير مسجل'),
                    dCell(inGeo),
                  ]);
                }),
              ],
            ),
          ],

          // Signature block
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('ختم المصلحة', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.SizedBox(height: 30),
                pw.Container(width: 100, height: 0.5, color: PdfColors.grey400),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                pw.Text('سطيف في: $dateStr', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 6),
                pw.Text('المدير الولائي للتجارة', style: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(directorName, style: pw.TextStyle(fontSize: 9, color: PdfColors.brown800)),
                pw.SizedBox(height: 24),
                pw.Container(width: 120, height: 0.5, color: PdfColors.grey400),
                pw.Text('التوقيع والختم', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
              ]),
            ],
          ),
        ],
      ));
    }

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Rapport_Statistiques_DCW_Setif_${periodStart}_to_${periodEnd}.pdf',
    );
  }

  static pw.Widget _buildKpiCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColor(color.red, color.green, color.blue, 0.08),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(value,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 3),
          pw.Text(label,
              style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
              textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }
}

