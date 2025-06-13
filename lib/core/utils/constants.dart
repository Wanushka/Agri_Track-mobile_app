enum LivestockFeature {
  farmTransfers,
  illnessRecords,
  milkYields
}

extension LivestockFeatureExtension on LivestockFeature {
  String get displayName {
    switch (this) {
      case LivestockFeature.farmTransfers:
        return 'Farm Transfers';
      case LivestockFeature.illnessRecords:
        return 'Illness Records';
      case LivestockFeature.milkYields:
        return 'Milk Yields';
    }
  }
  
  String get dbPath {
    switch (this) {
      case LivestockFeature.farmTransfers:
        return 'farmTransfers';
      case LivestockFeature.illnessRecords:
        return 'illnessRecords';
      case LivestockFeature.milkYields:
        return 'milkYields';
    }
  }
}