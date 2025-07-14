import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/investment_record.dart';
import '../providers/btc_provider.dart';

class InvestmentRecordCard extends StatelessWidget {
  final InvestmentRecord record;
  final VoidCallback onDelete;

  const InvestmentRecordCard({
    super.key,
    required this.record,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final btcProvider = Provider.of<BTCProvider>(context);
    final currentPrice = btcProvider.btcData?.price ?? 0.0;
    final roi = record.calculateROI(currentPrice);
    final roiColor = roi >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getZoneColor(record.zone),
          child: Text(
            record.zone.substring(0, 2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          record.formattedDate,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('投资: ${record.formattedAmount}'),
            Text('价格: ${record.formattedBTCPrice}'),
            Text('获得: ${record.formattedBTCAmount}'),
            Text('倍数: ${record.multiplier.toStringAsFixed(2)}x'),
            if (record.note != null && record.note!.isNotEmpty)
              Text('备注: ${record.note}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(2)}%',
              style: TextStyle(
                color: roiColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getZoneColor(String zone) {
    if (zone.contains('深蓝')) return Colors.indigo;
    if (zone.contains('蓝')) return Colors.blue;
    if (zone.contains('绿')) return Colors.green;
    if (zone.contains('黄')) return Colors.yellow;
    if (zone.contains('橙')) return Colors.orange;
    if (zone.contains('红')) return Colors.red;
    return Colors.grey;
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条投资记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
