import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/rainbow_dca_service.dart';
import '../models/investment_record.dart';
import '../providers/btc_provider.dart';
import '../services/api_service.dart';

class AddInvestmentScreen extends StatefulWidget {
  const AddInvestmentScreen({super.key});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentBTCPrice();
    // 监听金额和价格输入框的变化，实时更新预览
    _amountController.addListener(_updatePreview);
    _priceController.addListener(_updatePreview);
  }

  void _updatePreview() {
    setState(() {}); // 触发UI重建以更新预览
  }

  Future<void> _loadCurrentBTCPrice() async {
    final btcProvider = Provider.of<BTCProvider>(context, listen: false);
    if (btcProvider.btcData != null) {
      _priceController.text = btcProvider.btcData!.price.toStringAsFixed(2);
    } else {
      // 如果当前价格未加载，尝试获取当前日期价格
      await _fetchBTCPriceForSelectedDate(DateTime.now());
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2009), // Bitcoin genesis block
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchBTCPriceForSelectedDate(picked);
    }
  }

  Future<void> _fetchBTCPriceForSelectedDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _priceController.text = '获取价格中...';
    });
    try {
      final apiService = APIService();
      final price = await apiService.getBTCPriceByDate(date);
      _priceController.text = price.toStringAsFixed(2);
    } catch (e) {
      _priceController.text = '获取失败';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取历史BTC价格失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final btcPrice = double.parse(_priceController.text);
      final btcAmount = amount / btcPrice;

      // 计算彩虹DCA信息
      final rainbowResult = RainbowDCAService.calculateRainbowDCA(
        currentPrice: btcPrice,
        historicalData: [],
        baseAmount: amount,
      );

      final record = InvestmentRecord(
        date: _selectedDate,
        amount: amount,
        btcPrice: btcPrice,
        btcAmount: btcAmount,
        zone: rainbowResult.zone,
        multiplier: rainbowResult.multiplier,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      final storageService = await StorageService.getInstance();
      await storageService.addInvestmentRecord(record);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投资记录已保存')),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加投资记录'),
        actions: [
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveInvestment,
              child: const Text('保存'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 投资日期
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('投资日期'),
                  subtitle: Text(_formatDate(_selectedDate)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _selectDate(context),
                ),
              ),
              const SizedBox(height: 16),

              // 投资金额
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '投资金额',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          hintText: '100.00',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入投资金额';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return '请输入有效的金额';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // BTC价格
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BTC价格',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: const InputDecoration(
                          hintText: '50000.00',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入BTC价格';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return '请输入有效的价格';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 计算预览
              if (_amountController.text.isNotEmpty &&
                  _priceController.text.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '购买预览',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPreviewRow(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 备注
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '备注 (可选)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: '添加投资备注...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewRow() {
    final amount = double.tryParse(_amountController.text);
    final price = double.tryParse(_priceController.text);

    if (amount == null || price == null) {
      return const Text('输入金额和价格以查看预览');
    }

    final btcAmount = amount / price;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('投资金额:'),
            Text('\$${amount.toStringAsFixed(2)}'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('BTC价格:'),
            Text('\$${price.toStringAsFixed(2)}'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('获得BTC:'),
            Text('${btcAmount.toStringAsFixed(8)} BTC'),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
