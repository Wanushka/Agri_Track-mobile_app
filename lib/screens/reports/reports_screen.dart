import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/models/report.dart';

// Weekly Report Screen Widget - Main container for the report functionality
class WeeklyReportScreen extends StatefulWidget {
  @override
  _WeeklyReportScreenState createState() => _WeeklyReportScreenState();
}

// State class for Weekly Report Screen
class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  // Firebase database reference
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  // List to store report data
  List<Report> _reports = [];
  // Loading state indicator
  bool isLoading = true;
  // Primary theme color
  final Color primaryColor = const Color.fromARGB(255, 255, 150, 63);
  // PDF generation state
  bool _isGeneratingPDF = false;

  // Date range for filtering reports
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // Initialize state and load initial data
  @override
  void initState() {
    super.initState();
    _loadReportsForDateRange();
  }

  // Load reports from Firebase for the selected date range
  Future<void> _loadReportsForDateRange() async {
    try {
      setState(() => isLoading = true);

      // Adjust end date to include the entire day
      final adjustedEndDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      final snapshot = await _database.child('reports').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        _reports = [];

        data.forEach((key, value) {
          try {
            final reportData = Map<String, dynamic>.from(value as Map);
            if (reportData['category'] != null) {
              final report = Report.fromJson(reportData);

              // Filter by date range
              if (report.timestamp.isAfter(_startDate) &&
                  report.timestamp.isBefore(adjustedEndDate)) {
                _reports.add(report);
              }
            }
          } catch (e) {
            print('Error parsing report: $e');
          }
        });

        // Sort reports by timestamp (newest first)
        _reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading reports: $e');
      setState(() => isLoading = false);
    }
  }

  // Show date range picker dialog
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReportsForDateRange();
    }
  }

  // Generate and share PDF report
  Future<void> _generateAndDownloadPDF() async {
    try {
      setState(() => _isGeneratingPDF = true);
      final pdf = pw.Document();

      // Organize reports by category and limit the number of reports per category
      final int maxReportsPerCategory = 50; // Adjust this number based on your needs
      
      final healthReports = _reports
          .where((r) => r.category == 'Health')
          .take(maxReportsPerCategory)
          .toList();
      final environmentalReports = _reports
          .where((r) => r.category == 'Environmental')
          .take(maxReportsPerCategory)
          .toList();
      final waterReports = _reports
          .where((r) => r.category == 'Water')
          .take(maxReportsPerCategory)
          .toList();

      // Load custom fonts with error handling
      final fonts = await _loadFonts();

      // Calculate total reports for pagination warning
      final totalReports = healthReports.length + 
                          environmentalReports.length + 
                          waterReports.length;

      if (totalReports > 100) { // Show warning if too many reports
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Warning'),
            content: Text('You are trying to generate a PDF with Too Many reports. This might take a while and could be split into multiple documents. Would you like to proceed?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Proceed'),
              ),
            ],
          ),
        );

        if (proceed != true) {
          setState(() => _isGeneratingPDF = false);
          return;
        }
      }

      // Split reports into chunks if necessary
      final int maxPagesPerDocument = 50;
      final List<List<Report>> reportChunks = [];
      
      for (var reports in [healthReports, environmentalReports, waterReports]) {
        if (reports.isEmpty) continue;
        
        for (var i = 0; i < reports.length; i += maxPagesPerDocument) {
          final chunk = reports.skip(i).take(maxPagesPerDocument).toList();
          reportChunks.add(chunk);
        }
      }

      // Generate PDF for each chunk
      for (var i = 0; i < reportChunks.length; i++) {
        final chunk = reportChunks[i];
        final partNumber = reportChunks.length > 1 ? ' (Part ${i + 1})' : '';
        
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(32),
            maxPages: maxPagesPerDocument,
            header: (context) => _buildPdfHeader(context, fonts['regular']!, fonts['bold']!, partNumber),
            footer: (context) => _buildPdfFooter(context, fonts['regular']!),
            build: (context) => [
              // Summary section for first part only
              if (i == 0) ...[
                _buildSummarySection(fonts['regular']!, fonts['bold']!),
                pw.SizedBox(height: 20),
              ],

              // Reports for this chunk
              _buildChunkReportSection(chunk, fonts['regular']!, fonts['bold']!),
            ],
          ),
        );
      }

      // Save and preview the PDF
      final output = await getTemporaryDirectory();
      final String fileName = 'weekly_report_${DateFormat('yyyy-MM-dd').format(_startDate)}_to_${DateFormat('yyyy-MM-dd').format(_endDate)}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Show preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Weekly Bovi Track Report',
        subject: fileName,
      );

      setState(() => _isGeneratingPDF = false);
    } catch (e) {
      print('Error generating PDF: $e');
      setState(() => _isGeneratingPDF = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF. Please try with a smaller date range.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load custom fonts for PDF generation
  Future<Map<String, pw.Font>> _loadFonts() async {
    try {
      return {
        'regular': await PdfGoogleFonts.nunitoRegular(),
        'bold': await PdfGoogleFonts.nunitoBold(),
      };
    } catch (e) {
      print('Error loading fonts: $e');
      // Fallback to default fonts
      return {
        'regular': await PdfGoogleFonts.robotoBold(),
        'bold': await PdfGoogleFonts.robotoBold(),
      };
    }
  }

  // Build PDF header section
  pw.Widget _buildPdfHeader(pw.Context context, pw.Font font, pw.Font boldFont, [String partNumber = '']) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300))
      ),
      padding: pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bovi Track - Weekly Report$partNumber',
                style: pw.TextStyle(font: boldFont, fontSize: 20),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Container(
            width: 50,
            height: 50,
            decoration: pw.BoxDecoration(
              color: PdfColors.green,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                'BT',
                style: pw.TextStyle(
                  font: boldFont,
                  color: PdfColors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build PDF footer section
  pw.Widget _buildPdfFooter(pw.Context context, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated on ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  // Build PDF summary section with statistics
  pw.Widget _buildSummarySection(pw.Font font, pw.Font boldFont) {
    final healthCount = _reports.where((r) => 
      r.category == 'Health' && !r.message.toLowerCase().contains('heat')).length;
    final behaviorCount = _reports.where((r) => 
      r.category == 'Health' && r.message.toLowerCase().contains('heat')).length;
    final environmentalCount = _reports.where((r) => r.category == 'Environmental').length;
    final waterCount = _reports.where((r) => r.category == 'Water').length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Weekly Summary',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard('Health Reports', healthCount, PdfColors.red, font, boldFont),
              _buildSummaryCard('Behavior Reports', behaviorCount, PdfColors.brown, font, boldFont),
              _buildSummaryCard('Environmental Reports', environmentalCount, PdfColors.green, font, boldFont),
              _buildSummaryCard('Water Reports', waterCount, PdfColors.blue, font, boldFont),
            ],
          ),
        ),
      ],
    );
  }

  // Build individual summary cards for PDF
  pw.Widget _buildSummaryCard(String title, int count, PdfColor color, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt((color.toInt() & 0xFFFFFF) | (50 << 24)),
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              count.toString(),
              style: pw.TextStyle(
                font: boldFont,
                color: color,
                fontSize: 18,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Build category-specific report sections in PDF
  pw.Widget _buildCategoryReportSection(String category, List<Report> reports, pw.Font font, pw.Font boldFont) {
    final categoryColor = category == 'Health'
        ? PdfColors.red
        : (category == 'Environmental' ? PdfColors.green : PdfColors.blue);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          color: PdfColor.fromInt((categoryColor.toInt() & 0xFFFFFF) | (30 << 24)),
          padding: pw.EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: pw.Row(
            children: [
              pw.Container(
                width: 12,
                height: 12,
                decoration: pw.BoxDecoration(
                  color: categoryColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '$category Reports (${reports.length})',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        ...reports.map((report) => _buildReportItem(report, font, boldFont)),
        pw.SizedBox(height: 20),
      ],
    );
  }

  // Build individual report items in PDF
  pw.Widget _buildReportItem(Report report, pw.Font font, pw.Font boldFont) {
    String title = report.message.split('\n').first;
    String subtitle = report.message.split('\n').length > 1
        ? report.message.split('\n')[1]
        : '';

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8),
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: boldFont,
                  color: report.category == 'Health'
                      ? PdfColors.red
                      : (report.category == 'Environmental' ? PdfColors.green : PdfColors.blue),
                ),
              ),
              pw.Text(
                DateFormat('yyyy-MM-dd HH:mm').format(report.timestamp),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) pw.SizedBox(height: 4),
          if (subtitle.isNotEmpty)
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
              ),
            ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 4),
          pw.Text(
            'Recorded Values:',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          ...report.data.entries.map(
            (entry) => pw.Row(
              children: [
                pw.Text(
                  '${entry.key}: ',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                  ),
                ),
                pw.Text(
                  entry.value.toString(),
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build main UI screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Weekly Report'),
        backgroundColor: primaryColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        ),
        body: Column(
          children: [
            // Date range selector strip
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Period: ${DateFormat('MMM dd, yyyy').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => _selectDateRange(context),
                    child: Text('Change'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Report summary
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryWidget('Health',
                      _reports.where((r) => r.category == 'Health' && !r.message.toLowerCase().contains('heat')).length,
                      Colors.red),
                  _buildSummaryWidget('Behavior',
                      _reports.where((r) => r.category == 'Health' && r.message.toLowerCase().contains('heat')).length,
                      Color.fromARGB(255, 99, 104, 2)),
                  _buildSummaryWidget('Environmental',
                      _reports.where((r) => r.category == 'Environmental').length,
                      Color.fromARGB(255, 0, 255, 115)),
                  _buildSummaryWidget('Water',
                      _reports.where((r) => r.category == 'Water').length,
                      Colors.blue),
                ],
              ),
            ),

            // Reports list
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : _reports.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            return _buildReportCard(_reports[index]);
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isGeneratingPDF ? null : _generateAndDownloadPDF,
          icon: _isGeneratingPDF
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white))
              : Icon(Icons.picture_as_pdf),
          label: Text(_isGeneratingPDF ? 'Generating...' : 'Generate PDF'),
          backgroundColor: _isGeneratingPDF ? Colors.grey : primaryColor,
        ),
      );
    }

  // Build summary widgets for the UI
  Widget _buildSummaryWidget(String title, int count, Color color) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent,
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Build empty state widget when no reports are available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No reports found for this period',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadReportsForDateRange,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Build individual report cards for the list view
  Widget _buildReportCard(Report report) {
    String title = report.message.split('\n').first;
    String subtitle = report.message.split('\n').length > 1
        ? report.message.split('\n')[1]
        : '';

    // Define new color for behavior alerts
    Color cardColor = report.category == 'Health' && title.toLowerCase().contains('heat')
        ? Color.fromARGB(255, 99, 104, 2) // Purple color for behavior alerts
        : (report.category == 'Health'
            ? Colors.red
            : (report.category == 'Environmental'
                ? Color.fromARGB(255, 0, 255, 115)
                : Colors.blue));

    // Modify title for heat detection alerts
    String displayTitle = title.toLowerCase().contains('heat')
        ? title.replaceAll(RegExp('heat', caseSensitive: false), 'Behavior')
        : title;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cardColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: _getCategoryIcon(report.category, title),
        title: Text(
          displayTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cardColor,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(height: 1.5),
              ),
            SizedBox(height: 4),
            Text(
              DateFormat('yyyy-MM-dd HH:mm:ss').format(report.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showReportDetails(context, report),
      ),
    );
  }

  // Build category icon with appropriate styling
  Widget _getCategoryIcon(String category, String title) {
    String imagePath;
    Color backgroundColor;
    Color iconColor;

    // Special case for behavior alerts
    if (category == 'Health' && title.toLowerCase().contains('heat')) {
      imagePath = 'assets/images/behavior.png';
      backgroundColor = Color.fromARGB(255, 99, 104, 2).withOpacity(0.1);
      iconColor = Color.fromARGB(255, 99, 104, 2);
    } else {
      switch (category) {
        case 'Health':
          imagePath = 'assets/images/health.png';
          backgroundColor = Colors.red.withOpacity(0.1);
          iconColor = Colors.red;
          break;
        case 'Environmental':
          imagePath = 'assets/images/environment.png';
          backgroundColor = Color.fromARGB(255, 0, 255, 115).withOpacity(0.1);
          iconColor = Color.fromARGB(255, 0, 255, 115);
          break;
        case 'Water':
          imagePath = 'assets/images/environment.png';
          backgroundColor = Colors.blue.withOpacity(0.1);
          iconColor = Colors.blue;
          break;
        default:
          imagePath = 'assets/images/health.png';
          backgroundColor = Colors.grey.withOpacity(0.1);
          iconColor = Colors.grey;
          
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      padding: EdgeInsets.all(12),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        color: iconColor, // Apply the color to the image
        colorBlendMode: BlendMode.srcIn, // This ensures proper color blending
      ),
    );
  }

  // Show detailed report information in a dialog
  void _showReportDetails(BuildContext context, Report report) {
    String title = report.message.split('\n').first;
    String reportTitle = '';
    bool isBehaviorReport = report.category == 'Health' && title.toLowerCase().contains('heat');
    
    // Determine the report title
    if (report.category == 'Health') {
      if (isBehaviorReport) {
        reportTitle = 'Behavior Report';
      } else {
        reportTitle = 'Health Report';
      }
    } else {
      reportTitle = '${report.category} Report';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _getCategoryIcon(report.category, title),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reportTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd HH:mm:ss').format(report.timestamp),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailSection('Recorded Values', report.data),
              if (!isBehaviorReport) ...[
                SizedBox(height: 24),
                _buildDetailSection(
                    'Issues Detected',
                    {
                      title: report.message.split('\n').skip(1).join('\n')
                    },
                    isIssue: true),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
            style: TextButton.styleFrom(
              foregroundColor: _getCategoryColor(report.category),
            ),
          ),
        ],
      ),
    );
  }

  // Build detail sections for the report dialog
  Widget _buildDetailSection(String title, Map<String, dynamic> data,
      {bool isIssue = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isIssue ? Colors.red : Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        ...data.entries
            .map((entry) => Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isIssue ? Colors.red : Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  // Helper function to determine category color for UI elements
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Health':
        return Colors.red;
      // Color for environmental category indicators
      case 'Environmental':
        return Color.fromARGB(255, 0, 255, 115);
      // Color for water-related indicators
      case 'Water':
        return Colors.blue;
      // Default fallback color
      default:
        return Colors.grey;
    }
  }

  // Add this new helper method to build chunk report sections
  pw.Widget _buildChunkReportSection(List<Report> reports, pw.Font font, pw.Font boldFont) {
    if (reports.isEmpty) return pw.Container();

    final category = reports.first.category;
    final categoryColor = category == 'Health'
        ? PdfColors.red
        : (category == 'Environmental' ? PdfColors.green : PdfColors.blue);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          color: PdfColor.fromInt((categoryColor.toInt() & 0xFFFFFF) | (30 << 24)),
          padding: pw.EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: pw.Row(
            children: [
              pw.Container(
                width: 12,
                height: 12,
                decoration: pw.BoxDecoration(
                  color: categoryColor,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '$category Reports (${reports.length})',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        ...reports.map((report) => _buildReportItem(report, font, boldFont)),
        pw.SizedBox(height: 20),
      ],
    );
  }
}

// Add this to your main.dart or routes
// Navigation helper function to open the weekly report screen
// Can be used from any part of the app
void navigateToWeeklyReport(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => WeeklyReportScreen())
  );
}