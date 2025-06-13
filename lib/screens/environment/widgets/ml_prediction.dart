import 'package:flutter/material.dart';
import 'package:bovitrack/core/services/ml_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

/// Widget that displays and manages environmental condition predictions using ML
class MLPredictionWidget extends StatefulWidget {
  // Theme colors passed from parent
  final Color primaryColor;
  final Color cardColor;
  final Color textDarkColor;
  final Color textLightColor;
  // Latest environmental data for prediction
  final Map<String, dynamic>? environmentalLatestData;

  const MLPredictionWidget({
    Key? key,
    required this.primaryColor,
    required this.cardColor,
    required this.textDarkColor,
    required this.textLightColor,
    this.environmentalLatestData,
  }) : super(key: key);

  @override
  State<MLPredictionWidget> createState() => _MLPredictionWidgetState();
}

class _MLPredictionWidgetState extends State<MLPredictionWidget> {
  // ML service instance for making predictions
  final MilkMLService _mlService = MilkMLService();
  // State variables
  String? _prediction;
  bool _isLoading = false;
  String? _error;

  /// Fetches environmental prediction based on current conditions
  Future<void> _fetchPrediction() async {
    // Validate required environmental data
    if (widget.environmentalLatestData == null ||
        !widget.environmentalLatestData!.containsKey('Condition') ||
        !widget.environmentalLatestData!.containsKey('Temperature') ||
        !widget.environmentalLatestData!.containsKey('Humidity')) {
      setState(() => _error = 'Missing required environmental data');
      return;
    }

    try {
      // Set loading state
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Convert condition string to numeric value for ML model
      int conditionValue;
      String currentCondition = widget.environmentalLatestData!['Condition']?.toString().toLowerCase() ?? '';

      switch (currentCondition) {
        case 'good':
          conditionValue = 0;
          break;
        case 'medium':
          conditionValue = 1;
          break;
        case 'poor':
          conditionValue = 2;
          break;
        default:
          conditionValue = 0; // Default to good if unknown
      }

      // Parse temperature and humidity values
      final temperature = double.tryParse(
        widget.environmentalLatestData!['Temperature']?.toString().replaceAll('°C', '') ?? '0'
      ) ?? 0.0;

      final humidity = double.tryParse(
        widget.environmentalLatestData!['Humidity']?.toString().replaceAll('%', '') ?? '0'
      ) ?? 0.0;

      // Get prediction from ML service
      final prediction = await _mlService.predictFutureEnvCondition(
        conditionToday: conditionValue,
        tavgToday: temperature,
        humToday: humidity,
      );

      // Save prediction to Firebase with timestamp
      final DatabaseReference database = FirebaseDatabase.instance.ref();
      final String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      await database.child('future_prediction').push().set({
        'timestamp': timestamp,
        'input_data': {
          'condition': currentCondition,
          'temperature': temperature,
          'humidity': humidity,
        },
        'prediction': prediction,
      });

      // Update UI with prediction
      setState(() {
        _prediction = prediction;
        _isLoading = false;
      });

    } catch (e) {
      // Handle errors
      setState(() {
        _error = 'Failed to get prediction: $e';
        _isLoading = false;
      });
      print('Prediction error: $e');
    }
  }

  /// Returns appropriate emoji based on prediction condition
  String _getConditionEmoji(String prediction) {
    switch (prediction.toLowerCase()) {
      case 'good':
        return '🌟';
      case 'medium':
        return '⚠️';
      case 'poor':
        return '❗';
      default:
        return '📊';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main container with card styling
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Tooltip(
                message: 'AI-powered environmental condition prediction',
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: widget.primaryColor),
                    const SizedBox(width: 18),
                    Text(
                      'Future Prediction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.textDarkColor,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchPrediction,
                label: Text(_isLoading ? 'Analyzing...' : 'Get Predict'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Environmental Forecast',
            style: TextStyle(
              fontSize: 16,
              color: widget.textLightColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_prediction != null)
            _buildPredictionState(),
          if (!_isLoading && _prediction == null && _error == null)
            _buildInitialState(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Displays loading spinner and message while fetching prediction
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            color: widget.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 12),
          Text(
            'Analyzing environmental data...',
            style: TextStyle(
              color: widget.textLightColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays error message when prediction fails
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unable to generate prediction',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays prediction result with appropriate styling
  Widget _buildPredictionState() {
    final isHealthy = _prediction!.toLowerCase() == 'healthy';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHealthy 
            ? Colors.green.withOpacity(0.1) 
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHealthy 
              ? Colors.green.withOpacity(0.3) 
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getConditionEmoji(_prediction!),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Predicted Condition',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.textLightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _prediction!.toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              color: widget.textDarkColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on current temperature, humidity, and conditions',
            style: TextStyle(
              fontSize: 14,
              color: widget.textLightColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays initial state before prediction is requested
  Widget _buildInitialState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.primaryColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.touch_app,
            size: 32,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            'Tap "Get Predict" to get environmental forecast',
            style: TextStyle(
              color: widget.textLightColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}