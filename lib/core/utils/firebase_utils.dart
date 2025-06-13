// import 'package:firebase_database/firebase_database.dart';

// class FirebaseUtils {
//   static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
//   // Reference for temperature data
//   static final temperatureRef = FirebaseDatabase.instance.ref().child('temperatures');
  
//   // Save abnormal temperature reading
//   static Future<void> saveAbnormalTemperature({
//     required String deviceId,
//     required double temperature,
//     String? notes,
//   }) async {
//     try {
//       // Only save if temperature is abnormal (above 38.5°C)
//       if (temperature >= 38.5) {
//         final newTemperatureRef = temperatureRef.push();
//         await newTemperatureRef.set({
//           'deviceId': deviceId,
//           'temperature': temperature,
//           'timestamp': ServerValue.timestamp,
//           'notes': notes,
//         });
//       }
//     } catch (e) {
//       print('Error saving abnormal temperature: $e');
//       rethrow;
//     }
//   }

//   // Save abnormal data (for other health metrics)
//   static Future<void> saveAbnormalData({
//     required String deviceId,
//     required String type,
//     required Map<String, dynamic> data,
//     required String source,
//   }) async {
//     try {
//       final abnormalRef = _database.child('abnormal_events').push();
//       await abnormalRef.set({
//         'deviceId': deviceId,
//         'type': type,
//         'data': data,
//         'source': source,
//         'timestamp': ServerValue.timestamp,
//       });
//     } catch (e) {
//       print('Error saving abnormal data: $e');
//       rethrow;
//     }
//   }

//   // Delete temperature record
//   static Future<void> deleteTemperatureRecord(String recordId) async {
//     try {
//       await temperatureRef.child(recordId).remove();
//     } catch (e) {
//       print('Error deleting temperature record: $e');
//       rethrow;
//     }
//   }

//   // Get all temperature records for a specific device
//   static Query getDeviceTemperatures(String deviceId) {
//     return temperatureRef
//         .orderByChild('deviceId')
//         .equalTo(deviceId);
//   }
// }