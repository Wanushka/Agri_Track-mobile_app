import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bovitrack/core/services/ml_service.dart';
import 'package:bovitrack/core/constants/api_endpoints.dart';

class MLTestScreen extends StatefulWidget {
  const MLTestScreen({Key? key}) : super(key: key);

  @override
  State<MLTestScreen> createState() => _MLTestScreenState();
}

class _MLTestScreenState extends State<MLTestScreen> {
  final MilkMLService _mlService = MilkMLService();

  String _selectedTest = 'Milk Yield';
  bool _isLoading = false;
  String _result = '';
  String _errorMessage = '';

  final List<String> _testOptions = [
    'Milk Yield', 
    'Milk Quality', 
    'Future Environmental Condition'
  ];

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _errorMessage = '';
    });

    try {
      dynamic result;

      switch (_selectedTest) {
        case 'Milk Yield':
          result = await _mlService.predictMilkYield(
            lactationLength: 280.0,
            daysDry: 60.0,
            peakYield: 25.0,
            daysToPeak: 45.0,
          );
          _result = result != null
              ? const JsonEncoder.withIndent('  ').convert(result)
              : 'No result returned';
          break;

        case 'Milk Quality':
          final qualityResultMap = await _mlService.predictMilkQuality(
            pH: 6.7,
            temperature: 37.0,
            taste: 1,
            odor: 0,
            fat: 1,
            turbidity: 1,
            colour: 250,
          );
          if (qualityResultMap != null && qualityResultMap['quality'] is int) {
            int qualityResult = qualityResultMap['quality'];
            _result = 'Milk Quality: ${["Low", "Medium", "High"][qualityResult]}';
          } else {
            _result = 'No result returned';
          }
          break;

        case 'Future Environmental Condition':
          final envResult = await _mlService.predictFutureEnvCondition(
            conditionToday: 1,  // Example value: 1 for good condition
            tavgToday: 25.0,    // Example value: 25°C average temperature
            humToday: 65.0,     // Example value: 65% humidity
          );
          _result = 'Predicted Environmental Condition: $envResult';
          break;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ML Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown to select test type
            DropdownButtonFormField<String>(
              value: _selectedTest,
              decoration: const InputDecoration(
                labelText: 'Select Test',
                border: OutlineInputBorder(),
              ),
              items: _testOptions.map((test) {
                return DropdownMenuItem(value: test, child: Text(test));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTest = value;
                    _result = '';
                    _errorMessage = '';
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Run test button
            ElevatedButton(
              onPressed: _isLoading ? null : _runTest,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Run $_selectedTest Test'),
            ),
            const SizedBox(height: 20),

            // Error message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red[800]),
                ),
              ),

            // Result display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              constraints: const BoxConstraints(minHeight: 100),
              child: SelectableText(
                _result.isEmpty ? 'Result will appear here' : _result,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Safe method to get the current endpoint URL
  String _getEndpointUrl() {
    try {
      switch (_selectedTest) {
        case 'Milk Quality':
          return ApiEndpoints.milkqualityPrediction;
        case 'Milk Yield':
          return ApiEndpoints.milkyieldPrediction;
        case 'Future Environmental Condition':
          return ApiEndpoints.futureEnvCondition;
        default:
          return 'Unknown endpoint';
      }
    } catch (e) {
      return 'Error retrieving endpoint: $e';
    }
  }
}