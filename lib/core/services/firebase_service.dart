import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  static final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  static Stream<Map<String, dynamic>?> getFunction1Stream() {
    return _databaseRef.child('function1').onValue.map((event) {
      final Map<String, dynamic>? data = event.snapshot.value as Map<String, dynamic>?;
      print('Fetched function1 data: $data'); // Debug print
      return data;
    });
  }
}