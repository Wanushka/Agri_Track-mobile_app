import 'package:flutter/material.dart';
import 'package:bovitrack/core/services/ml_service.dart';
import 'package:bovitrack/screens/prediction/widgets/milk_color_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bovitrack/screens/prediction/widgets/error_dialog.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final Color primaryColor = const Color.fromARGB(255, 140, 84, 252);
  final Color secondaryColor = const Color.fromARGB(255, 182, 146, 254);
  final Color backgroundColor = const Color.fromARGB(255, 240, 255, 245);
  final _milkYieldFormKey = GlobalKey<FormState>();
  final _milkQualityFormKey = GlobalKey<FormState>();
  final _mlService = MilkMLService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Milk Yield Form Controllers
  final _lactationLengthController = TextEditingController();
  final _daysDryController = TextEditingController();
  final _peakYieldController = TextEditingController();
  final _daysToPeakController = TextEditingController();

  // Milk Quality Form Controllers
  final _phController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _colourController = TextEditingController();
  bool _taste = false;
  bool _odor = false;
  bool _fat = false;
  bool _turbidity = false;

  // Results
  String _milkYieldResult = '';
  String _milkQualityResult = '';
  bool _showYieldResult = false;
  bool _showQualityResult = false;
  String _yieldClass = '';
  String _qualityClass = '';

  // Selected Color
  int _selectedColor = 240;

  // Loading States
  bool _isLoadingYield = false;
  bool _isLoadingQuality = false;

  @override
  void dispose() {
    _lactationLengthController.dispose();
    _daysDryController.dispose();
    _peakYieldController.dispose();
    _daysToPeakController.dispose();
    _phController.dispose();
    _temperatureController.dispose();
    _colourController.dispose();
    super.dispose();
  }

  Future<void> _predictMilkYield() async {
    if (_milkYieldFormKey.currentState!.validate()) {
      try {
        setState(() {
          _showYieldResult = false;
          _isLoadingYield = true;
        });

        final result = await _mlService.predictMilkYield(
          lactationLength: double.parse(_lactationLengthController.text),
          daysDry: double.parse(_daysDryController.text),
          peakYield: double.parse(_peakYieldController.text),
          daysToPeak: double.parse(_daysToPeakController.text),
        );

        // Save prediction data to Firebase
        await _saveMilkYieldPrediction({
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'milk_yield',
          'inputs': {
            'lactation_length': double.parse(_lactationLengthController.text),
            'days_dry': double.parse(_daysDryController.text),
            'peak_yield': double.parse(_peakYieldController.text),
            'days_to_peak': double.parse(_daysToPeakController.text),
          },
          'results': {
            'predicted_yield': result['predicted_yield'],
            'predicted_class': result['predicted_class'],
          }
        });

        setState(() {
          _milkYieldResult =
              '${result['predicted_yield'].toStringAsFixed(2)} kg';
          _yieldClass = result['predicted_class'] == 1 ? 'High' : 'Low';
          _showYieldResult = true;
          _isLoadingYield = false;
        });
      } catch (e) {
        showErrorDialog(context, e.toString());
        setState(() {
          _showYieldResult = false;
          _isLoadingYield = false;
        });
      }
    }
  }

  Future<void> _predictMilkQuality() async {
    if (_milkQualityFormKey.currentState!.validate()) {
      try {
        setState(() {
          _showQualityResult = false;
          _isLoadingQuality = true; // Set loading state to true
        });

        final result = await _mlService.predictMilkQuality(
          pH: double.parse(_phController.text),
          temperature: double.parse(_temperatureController.text),
          taste: _taste ? 1 : 0,
          odor: _odor ? 1 : 0,
          fat: _fat ? 1 : 0,
          turbidity: _turbidity ? 1 : 0,
          colour: _selectedColor,
        );

        // Save prediction data to Firebase
        await _saveMilkQualityPrediction({
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'milk_quality',
          'inputs': {
            'ph': double.parse(_phController.text),
            'temperature': double.parse(_temperatureController.text),
            'taste': _taste,
            'odor': _odor,
            'fat': _fat,
            'turbidity': _turbidity,
            'colour': _selectedColor,
          },
          'results': {
            'quality': result['quality'],
            'quality_text': _milkQualityResult,
          }
        });

        String qualityText = '';
        switch (result['quality']) {
          case 0:
            qualityText = 'Low (Bad)';
            break;
          case 1:
            qualityText = 'Medium (Moderate)';
            break;
          case 2:
            qualityText = 'High (Good)';
            break;
          default:
            qualityText = 'Unknown';
        }

        setState(() {
          _milkQualityResult = qualityText;
          _qualityClass = qualityText;
          _showQualityResult = true;
          _isLoadingQuality = false; // Reset loading state
        });
      } catch (e) {
        // Show error dialog and reset states
        showErrorDialog(context, e.toString());
        setState(() {
          _showQualityResult = false;
          _isLoadingQuality = false;
        });
      }
    }
  }

  Future<void> _saveMilkYieldPrediction(
      Map<String, dynamic> predictionData) async {
    try {
      final newPredictionRef = _database.child('predictions').push();
      await newPredictionRef.set(predictionData);
    } catch (e) {
      print('Error saving milk yield prediction: $e');
    }
  }

  /// Saves milk quality prediction data to Firebase Realtime Database
  /// 
  /// [predictionData] - Map containing prediction input parameters and results
  /// Structure:
  /// - timestamp: ISO 8601 timestamp
  /// - type: 'milk_quality'
  /// - inputs: pH, temperature, taste, odor, fat, turbidity, colour
  /// - results: predicted quality and text description
  Future<void> _saveMilkQualityPrediction(
      Map<String, dynamic> predictionData) async {
    try {
      final newPredictionRef = _database.child('predictions').push();
      await newPredictionRef.set(predictionData);
    } catch (e) {
      print('Error saving milk quality prediction: $e');
    }
  }

  /// Builds consistent input field decoration across the app
  /// 
  /// [label] - Text label for the input field
  /// [icon] - Icon to show before the input field
  /// Returns an InputDecoration with:
  /// - Custom label and icon styling
  /// - Outlined border with rounded corners
  /// - Primary/secondary color scheme
  /// - Error state styling
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: secondaryColor),
      prefixIcon: Icon(icon, color: primaryColor),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildResultCard(String title, String result, String classType) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    IconData resultIcon;

    // Set color theme based on prediction result
    switch (classType) {
      case 'High (Good)':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        iconColor = Colors.green;
        resultIcon = Icons.check_circle;
        break;
      case 'Medium (Moderate)':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        iconColor = Colors.orange;
        resultIcon = Icons.horizontal_rule;
        break;
      case 'Low (Bad)':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        iconColor = Colors.red;
        resultIcon = Icons.cancel;
        break;
      case 'High': // For milk yield predictions
        backgroundColor = const Color.fromARGB(255, 172, 254, 214);
        textColor = Colors.green.shade900;
        iconColor = Colors.green;
        resultIcon = Icons.arrow_upward;
        break;
      case 'Low': // For milk yield predictions
        backgroundColor = const Color.fromARGB(255, 252, 233, 165);
        textColor = Colors.orange.shade900;
        iconColor = Colors.orange;
        resultIcon = Icons.arrow_downward;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade900;
        iconColor = Colors.grey;
        resultIcon = Icons.error;
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(resultIcon, size: 36, color: iconColor),
                const SizedBox(width: 16),
                Text(
                  result,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              classType,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: Container(
            margin: const EdgeInsets.all(8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          title: const Text('Prediction'),
          backgroundColor: primaryColor,
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(
                text: 'Milk Yield',
                icon: Icon(Icons.water_drop),
              ),
              Tab(
                text: 'Milk Quality',
                icon: Icon(Icons.verified),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Milk Yield Form
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _milkYieldFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Enter Milk Production Parameters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _lactationLengthController,
                              decoration: _buildInputDecoration(
                                'Lactation Length (days)',
                                Icons.calendar_today,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Required field';
                                if (double.tryParse(value!) == null)
                                  return 'Enter a valid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _daysDryController,
                              decoration: _buildInputDecoration(
                                'Days Dry',
                                Icons.hourglass_empty,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Required field';
                                if (double.tryParse(value!) == null)
                                  return 'Enter a valid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _peakYieldController,
                              decoration: _buildInputDecoration(
                                'Peak Yield (kg)',
                                Icons.show_chart,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Required field';
                                if (double.tryParse(value!) == null)
                                  return 'Enter a valid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _daysToPeakController,
                              decoration: _buildInputDecoration(
                                'Days to Peak',
                                Icons.trending_up,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true)
                                  return 'Required field';
                                if (double.tryParse(value!) == null)
                                  return 'Enter a valid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoadingYield ? null : _predictMilkYield,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoadingYield)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  else
                                    Icon(Icons.analytics, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    _isLoadingYield
                                        ? 'Predicting...'
                                        : 'Predict Milk Yield',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Result
                  if (_showYieldResult)
                    _buildResultCard(
                        'Predicted Milk Yield', _milkYieldResult, _yieldClass),
                ],
              ),
            ),

            // Milk Quality Form
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _milkQualityFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Enter Milk Quality Parameters',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _phController,
                              decoration: _buildInputDecoration(
                                'pH Level (3.0 - 9.0)',
                                Icons.science,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required field';
                                }
                                final ph = double.tryParse(value!);
                                if (ph == null) {
                                  return 'Enter a valid number';
                                }
                                if (ph < 3.0 || ph > 9.0) {
                                  return 'pH must be between 3.0 and 9.0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _temperatureController,
                              decoration: _buildInputDecoration(
                                'Temperature (10°C - 50°C)',
                                Icons.thermostat,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required field';
                                }
                                final temp = double.tryParse(value!);
                                if (temp == null) {
                                  return 'Enter a valid number';
                                }
                                if (temp < 10 || temp > 50) {
                                  return 'Temperature must be between 10°C and 50°C';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            MilkColorPicker(
                              selectedColor: _selectedColor,
                              onColorSelected: (color) {
                                setState(() {
                                  _selectedColor = color;
                                  _colourController.text = color.toString();
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            // Checkboxes with better styling
                            Card(
                              color: Colors.grey.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text(
                                      'Good Taste',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    value: _taste,
                                    activeColor: primaryColor,
                                    secondary: Icon(Icons.restaurant,
                                        color: primaryColor),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _taste = value ?? false;
                                      });
                                    },
                                  ),
                                  Divider(
                                      height: 1, color: Colors.grey.shade300),
                                  SwitchListTile(
                                    title: const Text(
                                      'Good Odor',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    value: _odor,
                                    activeColor: primaryColor,
                                    secondary:
                                        Icon(Icons.air, color: primaryColor),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _odor = value ?? false;
                                      });
                                    },
                                  ),
                                  Divider(
                                      height: 1, color: Colors.grey.shade300),
                                  SwitchListTile(
                                    title: const Text(
                                      'High Fat Content',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    value: _fat,
                                    activeColor: primaryColor,
                                    secondary: Icon(Icons.opacity,
                                        color: primaryColor),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _fat = value ?? false;
                                      });
                                    },
                                  ),
                                  Divider(
                                      height: 1, color: Colors.grey.shade300),
                                  SwitchListTile(
                                    title: const Text(
                                      'High Turbidity',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    value: _turbidity,
                                    activeColor: primaryColor,
                                    secondary: Icon(Icons.blur_on,
                                        color: primaryColor),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _turbidity = value ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _isLoadingQuality ? null : _predictMilkQuality,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoadingQuality)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  else
                                    Icon(Icons.analytics, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text(
                                    _isLoadingQuality
                                        ? 'Predicting...'
                                        : 'Predict Milk Quality',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Result
                  if (_showQualityResult)
                    _buildResultCard('Milk Quality Assessment', 'Quality Level',
                        _qualityClass),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
