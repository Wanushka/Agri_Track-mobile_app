import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bovitrack/core/constants/api_endpoints.dart';

class MilkMLService {
  // Predict milk yield using the /predict endpoint
  Future<Map<String, dynamic>> predictMilkYield({
    required double lactationLength,
    required double daysDry,
    required double peakYield,
    required double daysToPeak,
  }) async {
    try {
      var formData = {
        'lactation_length': lactationLength.toString(),
        'days_dry': daysDry.toString(),
        'peak_yield': peakYield.toString(),
        'days_to_peak': daysToPeak.toString(),
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.milkyieldPrediction),
        body: formData,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to predict milk yield: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error in milk yield prediction: $e');
    }
  }

  // Predict milk quality using the /milk_pred endpoint
  Future<Map<String, dynamic>> predictMilkQuality({
    required double pH,
    required double temperature,
    required int taste,
    required int odor,
    required int fat,
    required int turbidity,
    required int colour,
  }) async {
    try {
      var formData = {
        'pH': pH.toString(),
        'Temprature': temperature.toString(),
        'Taste': taste.toString(),
        'Odor': odor.toString(),
        'Fat': fat.toString(),
        'Turbidity': turbidity.toString(),
        'Colour': colour.toString(),
      };

      final response = await http.post(
        Uri.parse(ApiEndpoints.milkqualityPrediction),
        body: formData,
      );

      if (response.statusCode == 200) {
        int quality = int.parse(response.body);
        return {
          'quality': quality,
        };
      } else {
        throw Exception('Failed to predict milk quality: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error in milk quality prediction: $e');
    }
  }

  // Predict future environmental condition using the /future_env_condition endpoint
  Future<String> predictFutureEnvCondition({
    required int conditionToday,
    required double tavgToday,
    required double humToday,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.futureEnvCondition).replace(
        queryParameters: {
          'condition_today': conditionToday.toString(),
          'tavg_today': tavgToday.toString(),
          'hum_today': humToday.toString(),
        },
      );

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to predict future environmental condition: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error in future environmental condition prediction: $e');
    }
  }
}
