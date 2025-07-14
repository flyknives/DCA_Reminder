import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/investment_record.dart';
import '../providers/btc_provider.dart';
import '../widgets/investment_record_card.dart';
import 'add_investment_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseAmountController = TextEditingController();
  late StorageService _storageService;
  List<InvestmentRecord> _investmentRecords = [];
  InvestmentSummary? _investmentSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _storageService = await StorageService.getInstance();
    await _loadSettings();
    await _loadInvestmentRecords();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadSettings() async {
    final baseAmount = await _storageService.getBaseAmount();
    _baseAmountController.text = baseAmount.toStringAsFixed(2);
  }

  Future<void> _loadInvestmentRecords() async {
    final records = await _storageService.getInvestmentRecords();
    final btcProvider = Provider.of<BTCProvider>(context, listen: false);
    final currentPrice = btcProvider.btcData?.price ?? 0.0;

    final summary = await _storageService.getInvestmentSummary(currentPrice);

    setState(() {
      _investmentRecords = records;
      _investmentSummary = summary;
    });
  }

  Future<void> _saveBaseAmount() async {
    final amount = double.tryParse(_baseAmountController.text);
    if (amount != null && amount > 0) {
      await _storageService.setBaseAmount(amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('基准投资金额已保存')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的金额')),
      );
    }
  }

  Future<void> _deleteRecord(int index) async {
    await _storageService.deleteInvestmentRecord(index);
    await _loadInvestmentRecords();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('投资记录已删除')),
    );
  }

  Future<void> _clearAllRecords() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有投资记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.clearInvestmentRecords();
      await _loadInvestmentRecords();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有投资记录已清空')),
      );
    }
  }

  @override
  void dispose() {
    _baseAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddInvestmentScreen(),
                ),
              );
              if (result == true) {
                await _loadInvestmentRecords();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基准投资金额设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '基准投资金额',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '彩虹DCA算法将基于此金额计算建议买入金额',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('\$ '),
                        Expanded(
                          child: TextField(
                            controller: _baseAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            decoration: const InputDecoration(
                              hintText: '100.00',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _saveBaseAmount,
                          child: const Text('保存'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 投资统计摘要
            if (_investmentSummary != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '投资统计',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow(
                          '总投资', _investmentSummary!.formattedTotalInvested),
                      _buildStatRow(
                          '当前价值', _investmentSummary!.formattedCurrentValue),
                      _buildStatRow(
                          '总收益率', _investmentSummary!.formattedTotalROI),
                      _buildStatRow(
                          '平均买入价', _investmentSummary!.formattedAveragePrice),
                      _buildStatRow(
                          '总持有量', _investmentSummary!.formattedTotalBTC),
                      _buildStatRow(
                          '投资次数', '${_investmentSummary!.totalRecords}次'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 投资记录
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '投资记录',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_investmentRecords.isNotEmpty)
                          TextButton(
                            onPressed: _clearAllRecords,
                            child: const Text('清空所有'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_investmentRecords.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            '暂无投资记录\n点击右上角 + 按钮添加记录',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _investmentRecords.length,
                        itemBuilder: (context, index) {
                          final record = _investmentRecords[index];
                          return InvestmentRecordCard(
                            record: record,
                            onDelete: () => _deleteRecord(index),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
