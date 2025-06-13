import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// A screen widget that displays real-time behavior monitoring of cattle
/// including their location, behavior state, heat detection, and camera controls
class BehaviorScreen extends StatefulWidget {
  @override
  _BehaviorScreenState createState() => _BehaviorScreenState();
}

class _BehaviorScreenState extends State<BehaviorScreen> {
  // Firebase database references
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref("function1");
  final DatabaseReference function2Ref = FirebaseDatabase.instance.ref("function2");
  
  // Map controller for handling map interactions
  final MapController _mapController = MapController();

  // UI theme color
  final Color primaryColor = const Color.fromARGB(255, 74, 165, 245);
  
  // State variables
  Map<String, dynamic>? behaviorData;  // Stores current behavior data
  bool isLoading = true;               // Loading state indicator
  String selectedAngle = '90';         // Current camera angle
  final List<String> angles = ['0', '45', '90', '135', '180'];  // Available camera angles

  // Location tracking variables
  double latitude = 0.0;
  double longitude = 0.0;
  LatLng _lastKnownLocation = LatLng(0, 0);
  bool hasLocationData = false;

  // Cache the tile layer for map
  final TileLayer _tileLayer = TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.example.bovi-track',
    maxZoom: 18,
    tileProvider: NetworkTileProvider(),
  );

  // Add this state variable in _BehaviorScreenState class
  bool showBehaviorDetails = false;

  @override
  void initState() {
    super.initState();
    fetchBehaviorData();
    fetchLocationData();

    // Fetch initial angle from function2
    function2Ref.child('camera_angle').once().then((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        setState(() {
          selectedAngle = event.snapshot.value.toString();
        });
      }
    });
  }

  /// Processes location data from Firebase snapshot
  void _processLocationSnapshot(DataSnapshot snapshot) {
    try {
      if (snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        // Extract latitude and longitude directly from locations node
        var lat = data['latitude'];
        var lng = data['longitude'];

        if (lat != null && lng != null && mounted) {
          double newLat = (lat is double) ? lat : double.parse(lat.toString());
          double newLng = (lng is double) ? lng : double.parse(lng.toString());

          // Only update if location has changed
          if (newLat != latitude || newLng != longitude) {
            setState(() {
              latitude = newLat;
              longitude = newLng;
              hasLocationData = true;
              _lastKnownLocation = LatLng(latitude, longitude);
            });

            // Update map position
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _animateToLocation(_lastKnownLocation);
            });
            print('Location updated - Lat: $latitude, Lng: $longitude');
          }
        } else {
          print('Invalid location data: latitude or longitude is null');
        }
      }
    } catch (e) {
      print('Error processing location data: $e');
    }
  }

  /// Animates the map to a new location
  void _animateToLocation(LatLng location) {
    if (_mapController.camera.center != location) {
      _mapController.move(location, 15);
    }
  }

  /// Fetches real-time location updates from Firebase
  void fetchLocationData() {
    databaseRef.child('locations').onValue.listen((event) {
      _processLocationSnapshot(event.snapshot);
    });
  }

  /// Fetches behavior data including eating, lying, standing states and heat detection
  void fetchBehaviorData() {
    setState(() => isLoading = true);
    databaseRef.onValue.listen((event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && mounted) {
          // Handle behavior data
          String currentBehavior = 'Unknown';
          int behaviorValue = 0;

          if (data['behavior'] != null) {
            final behaviorMap = Map<String, dynamic>.from(data['behavior']);
            if (behaviorMap.isNotEmpty) {
              final latestTimestamp = behaviorMap.keys
                  .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
              final latestData = behaviorMap[latestTimestamp];

              // Check eating behavior
              if (latestData['eating'] != null && latestData['eating'] > 0) {
                currentBehavior = 'Eating';
                behaviorValue = latestData['eating'];
              }
              // Check lying behavior
              else if (latestData['lying'] != null && latestData['lying'] > 0) {
                currentBehavior = 'Lying';
                behaviorValue = latestData['lying'];
              }
              // Check standing behavior
              else if (latestData['standing'] != null && latestData['standing'] > 0) {
                currentBehavior = 'Standing';
                behaviorValue = latestData['standing'];
              }
            }
          }

          // Handle heat detection
          bool isHeatDetected = false;
          if (data['heat'] != null) {
            final heatMap = Map<String, dynamic>.from(data['heat']);
            if (heatMap.isNotEmpty) {
              final latestTimestamp = heatMap.keys
                  .reduce((a, b) => int.parse(a) > int.parse(b) ? a : b);
              isHeatDetected = heatMap[latestTimestamp]['isDetected'] ?? false;
            }
          }

          // Also check for location data in case it's part of the main data structure
          if (data['locations'] != null && !hasLocationData) {
            try {
              final locData = data['locations'];
              if (locData is Map &&
                  locData.containsKey('latitude') &&
                  locData.containsKey('longitude')) {
                final lat = locData['latitude'];
                final lng = locData['longitude'];

                if (lat != null && lng != null) {
                  setState(() {
                    latitude =
                        (lat is double) ? lat : double.parse(lat.toString());
                    longitude =
                        (lng is double) ? lng : double.parse(lng.toString());
                    hasLocationData = true;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _animateToLocation(LatLng(latitude, longitude));
                    });
                  });
                  print(
                      'Found location in main data structure: $latitude, $longitude');
                }
              }
            } catch (e) {
              print('Error processing location data from main structure: $e');
            }
          }

          setState(() {
            behaviorData = {
              'currentBehavior': currentBehavior,
              'behaviorValue': behaviorValue, // Add this line
              'isHeatDetected': isHeatDetected,
            };
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching behavior data: $e');
        if (mounted) {
          setState(() {
            behaviorData = {
              'currentBehavior': 'Unknown',
              'isHeatDetected': false,
            };
            isLoading = false;
          });
        }
      }
    });
  }

  /// Returns appropriate icon based on behavior type
  IconData _getBehaviorIcon(String behavior) {
    switch (behavior.toLowerCase()) {
      case 'eating':
        return Icons.restaurant;
      case 'lying':
        return Icons.hotel;
      case 'standing':
        return Icons.accessibility_new;
      default:
        return Icons.help_outline;
    }
  }

  /// Returns appropriate image asset path based on behavior type
  String _getBehaviorImage(String behavior) {
    switch (behavior.toLowerCase()) {
      case 'eating':
        return 'assets/images/eating.png';
      case 'lying':
        return 'assets/images/lying.png';
      case 'standing':
        return 'assets/images/standing.png';
      default:
        return 'assets/images/help.png';
    }
  }

  /// Returns the heat image asset path
  String _getHeatImage() {
    return 'assets/images/thermostat.png';
  }

  /// Builds a reusable info card widget with consistent styling
  Widget _buildInfoCard({
    required String title,
    String? imagePath,
    required Widget content,
    required Color iconColor,
    double? height,  // Add height parameter
  }) {
    return SizedBox(
      width: 130,
      height: height,  // Use the height parameter
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: primaryColor.withOpacity(0.3)),
        ),
        child:Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath,
                  height: 40,
                  width: 40,
                  color: iconColor,
                ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Expanded(  // Wrap content in Expanded
                child: content,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the map widget with current or last known location
  Widget _buildMap() {
    // Show the map with last known location even if current location is not available
    final location = hasLocationData ? LatLng(latitude, longitude) : _lastKnownLocation;
    final bool showingLastKnown = !hasLocationData && _lastKnownLocation.latitude != 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      width: MediaQuery.of(context).size.width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: !hasLocationData && !showingLastKnown
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Location data not available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: location,
                  initialZoom: 15,
                  keepAlive: true,
                  interactionOptions: InteractionOptions(
                    enableMultiFingerGestureRace: true,
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  _tileLayer,
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 80,
                        height: 80,
                        child: Column(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: showingLastKnown ? Colors.orange : Colors.red,
                              size: 40,
                            ),
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                showingLastKnown ? 'Last Known' : 'Current',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    databaseRef.onDisconnect();
    function2Ref.onDisconnect();
    super.dispose();
  }

  /// Main build method for the behavior screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Behavior Monitor'),
        backgroundColor: primaryColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : Column(
                children: [
                  // Top Section with Cards
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        // First Row with Behavior and Heat Cards
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                title: 'Behavior',
                                imagePath: showBehaviorDetails
                                    ? _getBehaviorImage(behaviorData!['currentBehavior'])
                                    : _getBehaviorImage('unknown'),
                                iconColor: primaryColor,
                                height: showBehaviorDetails ? 220 : 160,  // Adjust these values as needed
                                content: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (showBehaviorDetails) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        behaviorData!['currentBehavior'],
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Value: ${behaviorData!['behaviorValue']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: primaryColor.withOpacity(0.8),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          showBehaviorDetails = !showBehaviorDetails;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        showBehaviorDetails ? 'Hide Behavior' : 'Show Behavior',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildInfoCard(
                                title: 'Heat',
                                imagePath: _getHeatImage(),
                                iconColor: behaviorData!['isHeatDetected'] 
                                    ? Colors.red 
                                    : Colors.green,
                                height: showBehaviorDetails ? 220 : 160,
                                content: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: behaviorData!['isHeatDetected'] ? Colors.red : Colors.green,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        behaviorData!['isHeatDetected']
                                            ? 'Detected'
                                            : 'Not Detected',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: behaviorData!['isHeatDetected']
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),

                        // Camera Angle Card
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.camera_alt, size: 30, color: Colors.blue),
                                    SizedBox(width: 12),
                                    Text(
                                      'Camera Angle',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                DropdownButton<String>(
                                  value: selectedAngle,
                                  items: angles.map((String angle) {
                                    return DropdownMenuItem<String>(
                                      value: angle,
                                      child: Text(
                                        '$angle°',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        selectedAngle = newValue;
                                      });
                                      function2Ref
                                          .child('camera_angle')
                                          .set(int.parse(newValue));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map taking remaining space
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10 , vertical: 10),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: _buildMap(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}