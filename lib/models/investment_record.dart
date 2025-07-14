class InvestmentRecord {
  final DateTime date;
  final double amount;
  final double btcPrice;
  final double btcAmount;
  final String zone;
  final double multiplier;
  final String? note;

  InvestmentRecord({
    required this.date,
    required this.amount,
    required this.btcPrice,
    required this.btcAmount,
    required this.zone,
    required this.multiplier,
    this.note,
  });

  /// 从JSON创建投资记录
  factory InvestmentRecord.fromJson(Map<String, dynamic> json) {
    return InvestmentRecord(
      date: DateTime.parse(json['date']),
      amount: json['amount'].toDouble(),
      btcPrice: json['btcPrice'].toDouble(),
      btcAmount: json['btcAmount'].toDouble(),
      zone: json['zone'],
      multiplier: json['multiplier'].toDouble(),
      note: json['note'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'btcPrice': btcPrice,
      'btcAmount': btcAmount,
      'zone': zone,
      'multiplier': multiplier,
      'note': note,
    };
  }

  /// 计算投资回报率
  double calculateROI(double currentBTCPrice) {
    final currentValue = btcAmount * currentBTCPrice;
    return (currentValue - amount) / amount * 100;
  }

  /// 格式化显示
  String get formattedDate =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedBTCPrice => '\$${btcPrice.toStringAsFixed(2)}';
  String get formattedBTCAmount => '${btcAmount.toStringAsFixed(8)} BTC';
}

/// 投资统计摘要
class InvestmentSummary {
  final double totalInvested;
  final double totalBTCAmount;
  final double averagePrice;
  final int totalRecords;
  final double currentValue;
  final double totalROI;
  final DateTime firstInvestment;
  final DateTime lastInvestment;

  InvestmentSummary({
    required this.totalInvested,
    required this.totalBTCAmount,
    required this.averagePrice,
    required this.totalRecords,
    required this.currentValue,
    required this.totalROI,
    required this.firstInvestment,
    required this.lastInvestment,
  });

  String get formattedTotalInvested => '\$${totalInvested.toStringAsFixed(2)}';
  String get formattedCurrentValue => '\$${currentValue.toStringAsFixed(2)}';
  String get formattedTotalROI =>
      '${totalROI >= 0 ? '+' : ''}${totalROI.toStringAsFixed(2)}%';
  String get formattedAveragePrice => '\$${averagePrice.toStringAsFixed(2)}';
  String get formattedTotalBTC => '${totalBTCAmount.toStringAsFixed(8)} BTC';
}
