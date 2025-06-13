class Report {
  final String category;
  final DateTime timestamp;
  final String message;
  final Map<String, dynamic> data;

  Report({
    required this.category,
    required this.timestamp,
    required this.message,
    required this.data,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      category: json['category'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}