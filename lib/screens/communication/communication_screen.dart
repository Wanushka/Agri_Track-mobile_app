// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'dart:async';
import '../../core/models/stream_data_model.dart';

/// A screen widget that handles video streaming communication
/// Displays live MJPEG stream and stream metrics
class CommunicationScreen extends StatefulWidget {
  @override
  _CommunicationScreenState createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  // Stream configuration properties
  String? streamUrl;
  bool _isPlaying = false;
  StreamMetrics? currentMetrics;
  StreamSubscription<DatabaseEvent>? _metricsSubscription;
  final _streamKey = GlobalKey();
  
  // Reconnection handling properties
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 3;
  Timer? _reconnectTimer;
  bool _isConnecting = false;

  // UI Theme color
  final Color primaryColor = const Color.fromARGB(255, 110, 208, 4);

  @override
  void initState() {
    super.initState();
    // Initialize stream URL and metrics listeners
    _fetchStreamUrl();
    _listenToStreamMetrics();
  }

  /// Handles stream timeout by initiating reconnection process
  void _handleStreamTimeout() {
    if (mounted) {
      setState(() {
        _isReconnecting = true;
      });
      _handleReconnect();
    }
  }

  /// Listens to stream metrics updates from Firebase
  /// Updates UI with current stream quality metrics
  void _listenToStreamMetrics() {
    final DatabaseReference metricsRef =
        FirebaseDatabase.instance.ref().child('function2').child('stream_data');

    _metricsSubscription = metricsRef.onValue.listen((event) {
      if (!mounted) return;

      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            currentMetrics = StreamMetrics.fromMap(data);
          });
        } catch (e) {
          debugPrint('Error parsing stream metrics: $e');
        }
      }
    }, onError: (error) {
      debugPrint('Error fetching stream metrics: $error');
    });
  }

  /// Fetches and updates the stream URL from Firebase
  /// Sets up a listener for URL changes
  Future<void> _fetchStreamUrl() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("stream/url");
      ref.onValue.listen((event) {
        if (!mounted) return;

        if (event.snapshot.value != null) {
          String baseUrl = event.snapshot.value.toString();

          baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

          setState(() {
            streamUrl = baseUrl;
            debugPrint('Stream URL updated: $streamUrl');
          });
        }
      }, onError: (error) {
        debugPrint('Error fetching stream URL: $error');
      });
    } catch (e) {
      debugPrint('Error setting up stream URL listener: $e');
    }
  }

  /// Initiates the video stream
  /// Updates Firebase status and sends start request to stream server
  Future<void> _startStream() async {
    if (!mounted || streamUrl == null) return;

    setState(() {
      _isConnecting = true; // Set to true when starting
    });

    try {
      // Update Firebase stream_enabled status
      await FirebaseDatabase.instance
          .ref()
          .child('function2')
          .child('stream_enabled')
          .set(true);

      await Future.delayed(Duration(seconds: 10));

      String baseUrl = streamUrl!;
      // if (!baseUrl.startsWith('http')) {
      //   baseUrl = 'http://$baseUrl';
      // }

      final Uri controlUri = Uri.parse('$baseUrl/start_stream');

      debugPrint('Sending start request to: ${controlUri.toString()}');

      final response = await http.get(Uri.parse(baseUrl + '/start_stream'));

      // final response = await http.get(controlUri).timeout(
      //       const Duration(seconds: 5),
      //       onTimeout: () => throw TimeoutException('Connection timed out'),
      //     );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _isReconnecting = false;
            _reconnectAttempts = 0;
            _isConnecting = false; // Set to false when connected
          });
        }
      } else {
        debugPrint(
            'Failed to start stream: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to start stream: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });

      debugPrint('Error starting stream: $e');
      if (mounted && !_isReconnecting) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start stream: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      throw e;
    }
  }

  /// Stops the video stream
  /// Updates Firebase status and sends stop request to stream server
  Future<void> _stopStream() async {
    if (!mounted || streamUrl == null) return;

    try {
      final response = await http.get(Uri.parse('$streamUrl/stop_stream'));
      if (response.statusCode == 200) {
        setState(() {
          _isPlaying = false;
        });
      } else {
        debugPrint('Failed to stop stream: ${response.statusCode}');
      }

      await FirebaseDatabase.instance
          .ref()
          .child('function2')
          .child('stream_enabled')
          .set(false);
    } catch (e) {
      debugPrint('Error stopping stream: $e');
    }
  }

  /// Manages stream reconnection attempts
  /// Implements exponential backoff and max retry logic
  Future<void> _handleReconnect() async {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      setState(() {
        _isReconnecting = false;
        _isPlaying = false;
        _reconnectAttempts = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to reconnect after $maxReconnectAttempts attempts'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _reconnectAttempts = 0;
              _startStream();
            },
          ),
        ),
      );
      return;
    }

    _reconnectAttempts++;
    try {
      await _startStream();
      setState(() {
        _isReconnecting = false;
        _reconnectAttempts = 0;
      });
    } catch (e) {
      if (mounted) {
        // Wait for 2 seconds before trying again
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 2), _handleReconnect);
      }
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _reconnectTimer?.cancel();
    _metricsSubscription?.cancel();
    super.dispose();
  }

  /// Builds a metric display card widget
  /// Used for showing individual stream metrics like FPS, resolution, etc.
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color
  }) {
    return Container(
      width: 85,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Column(
            children: [
              Icon(icon, size: 24, color: color),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a responsive metric card widget
  /// Adapts to available space using LayoutBuilder
  Widget _buildResponsiveMetricCard(
    BoxConstraints constraints, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    // Calculate dynamic width based on container width
    double cardWidth = constraints.maxWidth <= 300 
        ? constraints.maxWidth 
        : (constraints.maxWidth / 2) - 12;
        
    // Ensure minimum width
    cardWidth = cardWidth.clamp(120.0, 200.0);

    return Container(
      width: cardWidth,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, size: 24, color: color),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateFpsFromSpeed(double? connectionSpeed) {
    if (connectionSpeed == null) return 24; // Default FPS
    
    // Define FPS thresholds based on connection speed (Mbps)
    if (connectionSpeed < 2) return 24;      // Low bandwidth
    if (connectionSpeed < 5) return 30;      // Medium bandwidth
    if (connectionSpeed < 10) return 60;     // High bandwidth
    return 120;                              // Very high bandwidth
  }

  @override
  Widget build(BuildContext context) {
    // Main UI build method
    // Contains:
    // 1. AppBar with navigation
    // 2. Stream display area
    // 3. Stream control buttons
    // 4. Metrics display panel
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Live Stream'),
        backgroundColor: primaryColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Expanded(
              child: streamUrl != null && _isPlaying
                  ? Stack(
                      children: [
                        Mjpeg(
                          key: _streamKey,
                          isLive: true,
                          stream:
                              '$streamUrl/video',
                          timeout: const Duration(seconds: 60),
                          error: (context, error, stack) {
                            // Handle timeout error
                            if (error is TimeoutException &&
                                mounted &&
                                !_isReconnecting) {
                              _handleStreamTimeout();
                            }
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isReconnecting
                                        ? 'Attempting to reconnect...'
                                        : 'Stream connection lost',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 16),
                                  if (!_isReconnecting)
                                    ElevatedButton(
                                      onPressed: _handleReconnect,
                                      child: Text('Reconnect'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (_isReconnecting)
                          Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                if (_isConnecting) ...[
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 0, 255, 115),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Connecting...",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Please wait while we connect to the stream",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.videocam_off_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Stream is not available",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Click 'Start Stream' to begin",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    // Add disabled color for better visual feedback
                    disabledBackgroundColor: Colors.grey,
                  ),
                  onPressed: _isPlaying
                      ? null
                      : _startStream, // Disable when streaming
                  child: Text("Start Stream",
                      style: TextStyle(
                          color: _isPlaying ? Colors.grey[400] : Colors.white)),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isPlaying
                      ? _stopStream
                      : null, // Enable only when streaming
                  child: Text("Stop Stream",
                      style: TextStyle(
                          color: _isPlaying ? Colors.white : Colors.grey[400])),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    // Add disabled color for better visual feedback
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 197, 254, 222),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: Colors.grey[800]),
                        SizedBox(width: 8),
                        Text(
                          'Stream Quality',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.start,
                        children: [
                          _buildResponsiveMetricCard(
                            constraints,
                            icon: Icons.high_quality,
                            label: "Resolution",
                            value: currentMetrics?.resolution ?? 'N/A',
                            color: Colors.green,
                          ),
                          _buildResponsiveMetricCard(
                            constraints,
                            icon: Icons.speed_rounded,
                            label: "FPS",
                            value: currentMetrics?.connectionSpeed != null 
                                ? "${_calculateFpsFromSpeed(currentMetrics?.connectionSpeed)}"
                                : 'N/A',
                            color: Colors.purple,
                          ),
                          _buildResponsiveMetricCard(
                            constraints,
                            icon: Icons.memory_rounded,
                            label: "Buffer",
                            value: currentMetrics?.bufferingRate != null
                                ? "${currentMetrics!.bufferingRate.toStringAsFixed(1)}x"
                                : 'N/A',
                            color: Colors.indigo,
                          ),
                          _buildResponsiveMetricCard(
                            constraints,
                            icon: Icons.network_check,
                            label: "Speed",
                            value: currentMetrics?.connectionSpeed != null
                                ? "${currentMetrics!.connectionSpeed.toStringAsFixed(1)} Mbps"
                                : 'N/A',
                            color: Colors.blue,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
