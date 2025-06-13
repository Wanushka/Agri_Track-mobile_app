import 'package:bovitrack/core/models/livestock_model.dart';
import 'package:bovitrack/core/services/livestock_service.dart';
import 'package:bovitrack/core/utils/constants.dart';
import 'package:bovitrack/screens/livestock/widgets/farm_transfer_form.dart';
import 'package:bovitrack/screens/livestock/widgets/feature_selector.dart';
import 'package:bovitrack/screens/livestock/widgets/illness_record_form.dart';
import 'package:bovitrack/screens/livestock/widgets/livestock_data_table.dart';
import 'package:bovitrack/screens/livestock/widgets/milk_yield_form.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class LivestockScreen extends StatefulWidget {
  const LivestockScreen({Key? key}) : super(key: key);

  @override
  State<LivestockScreen> createState() => _LivestockScreenState();
}

class _LivestockScreenState extends State<LivestockScreen> {
  // Selected feature
  LivestockFeature _currentFeature = LivestockFeature.farmTransfers;

  // Animal ID controller
  final _animalIdController = TextEditingController();

  // Database service
  final DatabaseService _databaseService = DatabaseService();

  // Data storage
  dynamic _recordData = [];
  bool _isLoading = false;
  bool _dataFetched = false;

  // Date range for milk yield report
  DateTime? _startDate;
  DateTime? _endDate;
  double _totalMilkYield = 0.0;
  bool _isGeneratingPDF = false;

  get primaryColor => Color.fromARGB(255, 0, 255, 115);
  get secondaryColor => Color.fromARGB(255, 197, 254, 222);

  @override
  void dispose() {
    _animalIdController.dispose();
    super.dispose();
  }

  Widget _buildLoadingIndicator() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading ${_currentFeature.displayName.toLowerCase()} data...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter an Animal ID and click "Load Data"\nto view records',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecordsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_currentFeature.displayName.toLowerCase()} found\nfor this Animal ID',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddRecordDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add New Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog() {
    if (_animalIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Animal ID first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildFormBasedOnFeature(),
        ),
      ),
    );
  }

  Widget _buildFormBasedOnFeature() {
    switch (_currentFeature) {
      case LivestockFeature.farmTransfers:
        return FarmTransferForm(
          animalId: _animalIdController.text,
          onSave: _saveFarmTransfer,
        );
      case LivestockFeature.illnessRecords:
        return IllnessRecordForm(
          animalId: _animalIdController.text,
          onSave: _saveIllnessRecord,
        );
      case LivestockFeature.milkYields:
        return MilkYieldForm(
          animalId: _animalIdController.text,
          onSave: _saveMilkYield,
        );
    }
  }

  Future<void> _saveFarmTransfer(FarmTransfer transfer) async {
    try {
      await _databaseService.saveFarmTransfer(_animalIdController.text, transfer);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm transfer saved successfully')),
      );
      _fetchAnimalData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving farm transfer: $e')),
      );
    }
  }

  Future<void> _saveIllnessRecord(IllnessRecord record) async {
    try {
      await _databaseService.saveIllnessRecord(_animalIdController.text, record);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Illness record saved successfully')),
      );
      _fetchAnimalData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving illness record: $e')),
      );
    }
  }

  // Saves milk yield data for a specific animal to the database
  Future<void> _saveMilkYield(MilkYield milkYield) async {
    try {
      // Attempt to save the milk yield data using the database service
      await _databaseService.saveMilkYield(_animalIdController.text, milkYield);
      
      // Show success message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Milk yield saved successfully')),
      );
      
      // Refresh the displayed data
      _fetchAnimalData();
    } catch (e) {
      // Show error message if saving fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving milk yield: $e')),
      );
    }
  }

  // Fetches animal data based on the selected feature (farm transfers, illness records, or milk yields)
  Future<void> _fetchAnimalData() async {
    final String animalId = _animalIdController.text.trim();

    // Validate that an animal ID was provided
    if (animalId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Animal ID')),
      );
      return;
    }

    // Reset the loading state and clear existing data
    setState(() {
      _isLoading = true;
      _recordData = [];
    });

    try {
      switch (_currentFeature) {
        case LivestockFeature.farmTransfers:
          final transfers = await _databaseService.fetchFarmTransfers(animalId);
          setState(() {
            _recordData = transfers;
          });
          break;
        case LivestockFeature.illnessRecords:
          final records = await _databaseService.fetchIllnessRecords(animalId);
          setState(() {
            _recordData = records;
          });
          break;
        case LivestockFeature.milkYields:
          final yields = await _databaseService.fetchMilkYields(animalId);
          setState(() {
            _recordData = yields;
          });
          break;
      }

      setState(() {
        _dataFetched = true;
      });

      if (_recordData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No ${_currentFeature.displayName} found for Animal ID: $animalId')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onFeatureChanged(LivestockFeature feature) {
    setState(() {
      _currentFeature = feature;
      _dataFetched = false;
      _recordData = [];  // Clear existing data
    });

    // Add subtle animation delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_animalIdController.text.isNotEmpty) {
        _fetchAnimalData();
      }
    });
  }

  Widget _buildDateRangeSelector() {
    String dateRangeText = 'Select Date Range';
    if (_startDate != null && _endDate != null) {
      dateRangeText = '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}';
    }

    return Visibility(
      visible: _currentFeature == LivestockFeature.milkYields && _recordData.isNotEmpty,
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: secondaryColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                DateTimeRange? dateRange = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _startDate != null && _endDate != null
                      ? DateTimeRange(start: _startDate!, end: _endDate!)
                      : null,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: primaryColor,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (dateRange != null) {
                  setState(() {
                    _startDate = dateRange.start;
                    _endDate = dateRange.end;
                    _calculateTotalMilkYield();
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.date_range, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dateRangeText,
                        style: TextStyle(
                          fontSize: 16,
                          color: _startDate == null ? Colors.grey[600] : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
          ),
          if (_startDate != null && _endDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Milk Yield',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_totalMilkYield.toStringAsFixed(2)} Liters',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _isGeneratingPDF
                    ? ElevatedButton.icon(
                        onPressed: null,
                        icon: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        label: const Text('Generating...'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor.withOpacity(0.7),
                          foregroundColor: Colors.white,
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _generateMilkYieldPDF,
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        label: const Text('Generate PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _calculateTotalMilkYield() {
    if (_startDate == null || _endDate == null) return;

    final filteredYields = (_recordData as List<MilkYield>).where((milkYield) {
      final yieldDate = DateFormat('yyyy-MM-dd').parse(milkYield.date);
      return yieldDate.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
             yieldDate.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();

    _totalMilkYield = filteredYields.fold(0.0, (sum, milkYield) => sum + milkYield.liters);
    setState(() {});
  }

  Future<void> _generateMilkYieldPDF() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    setState(() => _isGeneratingPDF = true);

    try {
      final pdf = pw.Document();

      // Load custom fonts
      final fonts = await _loadFonts();

      // Filter milk yields for selected date range
      final filteredYields = (_recordData as List<MilkYield>).where((milkYield) {
        final yieldDate = DateFormat('yyyy-MM-dd').parse(milkYield.date);
        return yieldDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
               yieldDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();

      // Sort yields by date
      filteredYields.sort((a, b) => 
        DateFormat('yyyy-MM-dd').parse(a.date)
            .compareTo(DateFormat('yyyy-MM-dd').parse(b.date)));

      // Add page to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildPdfHeader(context, fonts['regular']!, fonts['bold']!),
          footer: (context) => _buildPdfFooter(context, fonts['regular']!),
          build: (context) => [
            _buildPdfSummary(filteredYields, fonts['regular']!, fonts['bold']!),
            pw.SizedBox(height: 20),
            _buildPdfTable(filteredYields, fonts['regular']!, fonts['bold']!),
          ],
        ),
      );

      // Show preview first using the printing package
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      // After preview, handle saving and sharing
      final output = await getTemporaryDirectory();
      final String fileName = 'milk_yield_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');

      // Save PDF
      await file.writeAsBytes(await pdf.save());

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Milk Yield Report',
        subject: fileName,
      );

      setState(() => _isGeneratingPDF = false);

    } catch (e) {
      print('Error generating PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isGeneratingPDF = false);
    }
  }

  // Add these helper functions for PDF generation
  Future<Map<String, pw.Font>> _loadFonts() async {
    try {
      return {
        'regular': await PdfGoogleFonts.nunitoRegular(),
        'bold': await PdfGoogleFonts.nunitoBold(),
      };
    } catch (e) {
      print('Error loading fonts: $e');
      return {
        'regular': await PdfGoogleFonts.robotoBold(),
        'bold': await PdfGoogleFonts.robotoBold(),
      };
    }
  }

  pw.Widget _buildPdfHeader(pw.Context context, pw.Font font, pw.Font boldFont) {
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
                'Milk Yield Report',
                style: pw.TextStyle(font: boldFont, fontSize: 20),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Animal ID: ${_animalIdController.text}',
                style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey700),
              ),
              pw.Text(
                '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
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

  pw.Widget _buildPdfSummary(List<MilkYield> yields, pw.Font font, pw.Font boldFont) {
    double avgYield = yields.isEmpty ? 0 : 
      yields.fold(0.0, (sum, yield) => sum + yield.liters) / yields.length;
    double maxYield = yields.isEmpty ? 0 : 
      yields.map((y) => y.liters).reduce((max, y) => y > max ? y : max);
    double minYield = yields.isEmpty ? 0 : 
      yields.map((y) => y.liters).reduce((min, y) => y < min ? y : min);

    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildPdfSummaryCard('Total Yield', '${_totalMilkYield.toStringAsFixed(2)} L', font, boldFont),
          _buildPdfSummaryCard('Average', '${avgYield.toStringAsFixed(2)} L', font, boldFont),
          _buildPdfSummaryCard('Maximum', '${maxYield.toStringAsFixed(2)} L', font, boldFont),
          _buildPdfSummaryCard('Minimum', '${minYield.toStringAsFixed(2)} L', font, boldFont),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummaryCard(String title, String value, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTable(List<MilkYield> yields, pw.Font font, pw.Font boldFont) {
    return pw.TableHelper.fromTextArray(
      context: null,
      headers: ['Date', 'Milk Yield (Liters)'],
      headerStyle: pw.TextStyle(font: boldFont),
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      data: yields.map((yield) => [
        DateFormat('yyyy-MM-dd').format(DateFormat('yyyy-MM-dd').parse(yield.date)),
 // Replace 'time' with the actual property name if different
        yield.liters.toStringAsFixed(2),
      ]).toList(),
      cellStyle: pw.TextStyle(font: font),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
      },
    );
  }

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
        title: const Text('Livestock Management'),
        backgroundColor: primaryColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_animalIdController.text.isNotEmpty) {
            await _fetchAnimalData();
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feature Selector (Tabs) instead of dropdown
                FeatureSelector(
                  selectedFeature: _currentFeature,
                  onFeatureSelected: _onFeatureChanged,
                ),

                const SizedBox(height: 24),

                // Animal ID input and fetch button
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _animalIdController,
                        decoration: InputDecoration(
                          labelText: 'Animal ID',
                          hintText: 'Enter the animal ID',
                          suffixIcon: _animalIdController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _animalIdController.clear();
                                    _dataFetched = false;
                                    _recordData = [];
                                  });
                                },
                              )
                            : null,
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _dataFetched = false;
                          });
                        },
                        textInputAction: TextInputAction.search,
                        onFieldSubmitted: (_) => _fetchAnimalData(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchAnimalData,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: const Text('Load Data', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Record count and add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentFeature.displayName} Records',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_dataFetched && _recordData.isNotEmpty)
                      Text('Total: ${_recordData.length} records'),
                  ],
                ),

                const SizedBox(height: 10),

                // Date range selector for milk yield feature
                _buildDateRangeSelector(),

                const SizedBox(height: 16),

                // Data Table
                Container(
                  height: 500,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: secondaryColor),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _isLoading
                      ? _buildLoadingIndicator()
                      : !_dataFetched
                        ? _buildEmptyState()
                        : _recordData.isEmpty
                          ? _buildNoRecordsFound()
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LivestockDataTable(
                                    feature: _currentFeature,
                                    isLoading: _isLoading,
                                    dataFetched: _dataFetched,
                                    recordData: _recordData,
                                  ),
                                ],
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Floating action button to add new record
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRecordDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Data', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        tooltip: 'Add a new record',
      ),
    );
  }
}