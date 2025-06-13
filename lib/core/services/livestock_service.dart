import 'package:bovitrack/core/models/livestock_model.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // Save a farm transfer record
  Future<void> saveFarmTransfer(String animalId, FarmTransfer transfer) async {
    final newTransferRef = _databaseRef
        .child('livestock')
        .child(animalId)
        .child('farmTransfers')
        .push();
    
    await newTransferRef.set(transfer.toMap());
  }

  // Save an illness record
  Future<void> saveIllnessRecord(String animalId, IllnessRecord record) async {
    final newIllnessRef = _databaseRef
        .child('livestock')
        .child(animalId)
        .child('illnessRecords')
        .push();
    
    await newIllnessRef.set(record.toMap());
  }

  // Save a milk yield record
  Future<void> saveMilkYield(String animalId, MilkYield milkYield) async {
    final newYieldRef = _databaseRef
        .child('livestock')
        .child(animalId)
        .child('milkYields')
        .push();
    
    await newYieldRef.set(milkYield.toMap());
  }

  // Fetch farm transfers for an animal
  Future<List<FarmTransfer>> fetchFarmTransfers(String animalId) async {
    final dataSnapshot = await _databaseRef
        .child('livestock')
        .child(animalId)
        .child('farmTransfers')
        .get();
    
    if (dataSnapshot.exists) {
      final data = dataSnapshot.value as Map<dynamic, dynamic>;
      List<FarmTransfer> transfers = [];
      
      data.forEach((key, value) {
        transfers.add(FarmTransfer.fromMap(key.toString(), Map<String, dynamic>.from(value)));
      });
      
      // Sort by timestamp (newest first)
      transfers.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return transfers;
    }
    
    return [];
  }

  // Fetch illness records for an animal
  Future<List<IllnessRecord>> fetchIllnessRecords(String animalId) async {
    final dataSnapshot = await _databaseRef
        .child('livestock')
        .child(animalId)
        .child('illnessRecords')
        .get();
    
    if (dataSnapshot.exists) {
      final data = dataSnapshot.value as Map<dynamic, dynamic>;
      List<IllnessRecord> records = [];
      
      data.forEach((key, value) {
        records.add(IllnessRecord.fromMap(key.toString(), Map<String, dynamic>.from(value)));
      });
      
      // Sort by timestamp (newest first)
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return records;
    }
    
    return [];
  }

  // Fetch milk yields for an animal
  Future<List<MilkYield>> fetchMilkYields(String animalId) async {
    final dataSnapshot = await _databaseRef
        .child('livestock')
        .child(animalId)
        .child('milkYields')
        .get();
    
    if (dataSnapshot.exists) {
      final data = dataSnapshot.value as Map<dynamic, dynamic>;
      List<MilkYield> yields = [];
      
      data.forEach((key, value) {
        yields.add(MilkYield.fromMap(key.toString(), Map<String, dynamic>.from(value)));
      });
      
      // Sort by timestamp (newest first)
      yields.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return yields;
    }
    
    return [];
  }
}