class Device {
  final BehaviorData behavior;
  final bool isDetected;
  final double latitude;
  final double longitude;

  Device({
    required this.behavior,
    required this.isDetected,
    required this.latitude,
    required this.longitude,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    // Extract function1 data
    Map<String, dynamic> function1Data = json;

    // Get behavior with latest timestamp
    Map<String, dynamic> behaviorMap = function1Data['behavior'] ?? {};
    String latestBehaviorTimestamp = '';
    BehaviorData behaviorData;

    if (behaviorMap.isNotEmpty) {
      // Find the latest timestamp (highest key)
      latestBehaviorTimestamp = behaviorMap.keys
          .map((key) => int.tryParse(key) ?? 0)
          .reduce((a, b) => a > b ? a : b)
          .toString();
      behaviorData = BehaviorData.fromJson(behaviorMap[latestBehaviorTimestamp]);
    } else {
      behaviorData = BehaviorData(eating: 0, lying: 0, standing: 0);
    }

    // Get heat with latest timestamp
    Map<String, dynamic> heatMap = function1Data['heat'] ?? {};
    bool detectedStatus = false;

    if (heatMap.isNotEmpty) {
      // Find the latest timestamp (highest key)
      String latestHeatTimestamp = heatMap.keys
          .map((key) => int.tryParse(key) ?? 0)
          .reduce((a, b) => a > b ? a : b)
          .toString();
      detectedStatus = heatMap[latestHeatTimestamp]?['isDetected'] ?? false;
    }

    // Get location data
    // Get location data with latest timestamp
    Map<String, dynamic> locationsMap = function1Data['locations'] ?? {};
    double lat = 0.0, lon = 0.0;

    if (locationsMap.isNotEmpty) {
      // Check if locations is a map of timestamps
      if (locationsMap.values.first is Map) {
        // Find the latest timestamp
        String latestLocationTimestamp = locationsMap.keys
            .map((key) => int.tryParse(key) ?? 0)
            .reduce((a, b) => a > b ? a : b)
            .toString();
            
        var latestLocation = locationsMap[latestLocationTimestamp];
        var latitude = latestLocation['latitude'];
        var longitude = latestLocation['longitude'];

        if (latitude != 'N/A' && longitude != 'N/A') {
          lat = double.tryParse(latitude.toString()) ?? 0.0;
          lon = double.tryParse(longitude.toString()) ?? 0.0;
        }
      } else {
        // Handle direct location data
        var latitude = locationsMap['latitude'];
        var longitude = locationsMap['longitude'];

        if (latitude != 'N/A' && longitude != 'N/A') {
          lat = double.tryParse(latitude.toString()) ?? 0.0;
          lon = double.tryParse(longitude.toString()) ?? 0.0;
        }
      }
    }

    return Device(
      behavior: behaviorData,
      isDetected: detectedStatus,
      latitude: lat,
      longitude: lon,
    );
  }

  @override
  String toString() {
    return 'Device(behavior: $behavior, isDetected: $isDetected, latitude: $latitude, longitude: $longitude)';
  }
}

class BehaviorData {
  final double eating;
  final double lying;
  final double standing;

  BehaviorData({
    required this.eating,
    required this.lying,
    required this.standing,
  });

  factory BehaviorData.fromJson(Map<String, dynamic> json) {
    return BehaviorData(
      eating: (json['eating'] ?? 0.0).toDouble(),
      lying: (json['lying'] ?? 0.0).toDouble(),
      standing: (json['standing'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'BehaviorData(eating: $eating, lying: $lying, standing: $standing)';
  }
}