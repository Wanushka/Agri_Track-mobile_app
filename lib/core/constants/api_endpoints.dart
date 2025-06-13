// import 'package:bovitrack/config/env_config.dart';

class ApiEndpoints {
  // Base URL - Get IP from EnvConfig
  static final String baseUrl = 'https://bovitrack-api-6b5cc183c1c5.herokuapp.com';

  // Prediction endpoints
  static final String milkyieldPrediction = '$baseUrl/predict';
  static final String milkqualityPrediction = '$baseUrl/milk_pred';
  static final String futureEnvCondition = '$baseUrl/future_env_condition';
  static final String environmentalConditionPrediction = '$baseUrl/env_con';
}
