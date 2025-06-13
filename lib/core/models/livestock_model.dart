// Base abstract class for all livestock record types
abstract class LivestockRecord {
  final String id;
  final int timestamp;

  LivestockRecord({
    required this.id,
    required this.timestamp,
  });

  Map<String, dynamic> toMap();
  
  factory LivestockRecord.fromMap(String id, Map<String, dynamic> map) {
    throw UnimplementedError('This method should be implemented by subclasses');
  }
}

// Farm Transfer model
class FarmTransfer extends LivestockRecord {
  final String year;
  final String month;
  final double weight;
  final String fromFarm;
  final String toFarm;

  FarmTransfer({
    required String id,
    required int timestamp,
    required this.year,
    required this.month,
    required this.weight,
    required this.fromFarm,
    required this.toFarm,
  }) : super(id: id, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() {
    return {
      'year': year,
      'month': month,
      'weight': weight,
      'fromFarm': fromFarm,
      'toFarm': toFarm,
      'timestamp': timestamp,
    };
  }

  factory FarmTransfer.fromMap(String id, Map<String, dynamic> map) {
    return FarmTransfer(
      id: id,
      timestamp: map['timestamp'] ?? 0,
      year: map['year'] ?? '',
      month: map['month'] ?? '',
      weight: (map['weight'] is int)
          ? (map['weight'] as int).toDouble()
          : (map['weight'] ?? 0.0),
      fromFarm: map['fromFarm'] ?? '',
      toFarm: map['toFarm'] ?? '',
    );
  }
}

// Illness Record model
class IllnessRecord extends LivestockRecord {
  final String date;
  final String illnessDetails;
  final String treatment;

  IllnessRecord({
    required String id,
    required int timestamp,
    required this.date,
    required this.illnessDetails,
    required this.treatment,
  }) : super(id: id, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'illnessDetails': illnessDetails,
      'treatment': treatment,
      'timestamp': timestamp,
    };
  }

  factory IllnessRecord.fromMap(String id, Map<String, dynamic> map) {
    return IllnessRecord(
      id: id,
      timestamp: map['timestamp'] ?? 0,
      date: map['date'] ?? '',
      illnessDetails: map['illnessDetails'] ?? '',
      treatment: map['treatment'] ?? '',
    );
  }
}

// Milk Yield model
class MilkYield extends LivestockRecord {
  final String date;  // Changed from year and month to date
  final double liters;

  MilkYield({
    required String id,
    required int timestamp,
    required this.date,
    required this.liters,
  }) : super(id: id, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'liters': liters,
      'timestamp': timestamp,
    };
  }

  factory MilkYield.fromMap(String id, Map<String, dynamic> map) {
    return MilkYield(
      id: id,
      timestamp: map['timestamp'] ?? 0,
      date: map['date'] ?? '',
      liters: (map['liters'] is int)
          ? (map['liters'] as int).toDouble()
          : (map['liters'] ?? 0.0),
    );
  }
}