import 'package:bovitrack/core/models/livestock_model.dart';
import 'package:bovitrack/core/utils/constants.dart';
import 'package:flutter/material.dart';

class LivestockDataTable extends StatelessWidget {
  final LivestockFeature feature;
  final bool isLoading;
  final bool dataFetched;
  final dynamic recordData;

  const LivestockDataTable({
    Key? key,
    required this.feature,
    required this.isLoading,
    required this.dataFetched,
    required this.recordData,
  }) : super(key: key);

  Widget _buildFarmTransfersTable(List<FarmTransfer> transfers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DataTable(
          columnSpacing: 8,
          horizontalMargin: 8,
          columns: const [
            DataColumn(label: Expanded(
              child: Text('Year', textAlign: TextAlign.center),
            )),
            DataColumn(label: Expanded(
              child: Text('Month', textAlign: TextAlign.center),
            )),
            DataColumn(label: Expanded(
              child: Text('Weight', textAlign: TextAlign.center),
            )),
            DataColumn(label: Expanded(
              child: Text('From', textAlign: TextAlign.center),
            )),
            DataColumn(label: Expanded(
              child: Text('To', textAlign: TextAlign.center),
            )),
          ],
          rows: transfers.map((transfer) {
            return DataRow(cells: [
              DataCell(Center(child: Text(transfer.year))),
              DataCell(Center(child: Text(transfer.month))),
              DataCell(Center(child: Text('${transfer.weight}kg'))),
              DataCell(Center(child: Text(transfer.fromFarm))),
              DataCell(Center(child: Text(transfer.toFarm))),
            ]);
          }).toList(),
        );
      },
    );
  }

  Widget _buildIllnessRecordsTable(List<IllnessRecord> records) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DataTable(
          columnSpacing: 8,
          horizontalMargin: 8,
          columns: const [
            DataColumn(label: Expanded(
              child: Text('Date', textAlign: TextAlign.center),
            )),
            DataColumn(label: Expanded(
              child: Text('Illness', textAlign: TextAlign.center),
            )),
            DataColumn(label: Expanded(
              child: Text('Treatment', textAlign: TextAlign.center),
            )),
          ],
          rows: records.map((record) {
            return DataRow(cells: [
              DataCell(Center(child: Text(record.date))),
              DataCell(Center(child: Text(record.illnessDetails))),
              DataCell(Center(child: Text(record.treatment))),
            ]);
          }).toList(),
        );
      },
    );
  }

  Widget _buildMilkYieldsTable(List<MilkYield> yields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DataTable(
          columnSpacing: 8,
          horizontalMargin: 8,
          columns: const [
            DataColumn(label: Expanded(
              child: Text('Date', textAlign: TextAlign.center),
            )),
            DataColumn(label: Expanded(
              child: Text('Milk (Liters)', textAlign: TextAlign.center),
            )),
          ],
          rows: yields.map((yield) {
            return DataRow(cells: [
              DataCell(Center(child: Text(yield.date))),
              DataCell(Center(child: Text(yield.liters.toString()))),
            ]);
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (!dataFetched) {
      return const Center(
        child: Text('Enter an Animal ID and click "Load Data" to view records'),
      );
    }
    
    if (recordData.isEmpty) {
      return const Center(child: Text('No records found'));
    }
    
    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: switch (feature) {
          LivestockFeature.farmTransfers => _buildFarmTransfersTable(recordData as List<FarmTransfer>),
          LivestockFeature.illnessRecords => _buildIllnessRecordsTable(recordData as List<IllnessRecord>),
          LivestockFeature.milkYields => _buildMilkYieldsTable(recordData as List<MilkYield>),
        },
      ),
    );
  }
}