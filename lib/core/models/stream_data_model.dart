class StreamMetrics {
  final double bufferingRate;
  final double connectionSpeed;
  final int fps;
  final String resolution;

  StreamMetrics({
    required this.bufferingRate,
    required this.connectionSpeed,
    required this.fps,
    required this.resolution,
  });

  factory StreamMetrics.fromMap(Map<String, dynamic> map) {
    return StreamMetrics(
      bufferingRate: (map['buffering_rate'] ?? 0.0).toDouble(),
      connectionSpeed: (map['connection_speed'] ?? 0.0).toDouble(),
      fps: (map['fps'] ?? 0) as int,
      resolution: (map['resolution'] ?? '360p').toString(),
    );
  }
}