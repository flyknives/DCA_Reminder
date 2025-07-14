class BTCData {
  final double price;
  final double priceChange24h;
  final double priceChangePercent24h;
  final DateTime timestamp;
  final String symbol;

  BTCData({
    required this.price,
    required this.priceChange24h,
    required this.priceChangePercent24h,
    required this.timestamp,
    this.symbol = 'BTCUSDT',
  });

  factory BTCData.fromJson(Map<String, dynamic> json) {
    return BTCData(
      price: double.parse(json['lastPrice']),
      priceChange24h: double.parse(json['priceChange']),
      priceChangePercent24h: double.parse(json['priceChangePercent']),
      timestamp: DateTime.now(),
      symbol: json['symbol'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'priceChange24h': priceChange24h,
      'priceChangePercent24h': priceChangePercent24h,
      'timestamp': timestamp.toIso8601String(),
      'symbol': symbol,
    };
  }

  @override
  String toString() {
    return 'BTCData{price: $price, change: $priceChangePercent24h%, time: $timestamp}';
  }
}

class HistoricalData {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final DateTime timestamp;

  HistoricalData({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timestamp,
  });

  factory HistoricalData.fromKlineData(List<dynamic> kline) {
    return HistoricalData(
      open: double.parse(kline[1]),
      high: double.parse(kline[2]),
      low: double.parse(kline[3]),
      close: double.parse(kline[4]),
      volume: double.parse(kline[5]),
      timestamp: DateTime.fromMillisecondsSinceEpoch(kline[0]),
    );
  }

  factory HistoricalData.fromJson(Map<String, dynamic> json) {
    return HistoricalData(
      open: json['open'].toDouble(),
      high: json['high'].toDouble(),
      low: json['low'].toDouble(),
      close: json['close'].toDouble(),
      volume: json['volume'].toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class RainbowDCAResult {
  final double currentPrice;
  final double regressionPrice;
  final double priceRatio;
  final double multiplier;
  final double suggestedAmount;
  final String zone;
  final String marketStatus;
  final DateTime calculatedAt;

  RainbowDCAResult({
    required this.currentPrice,
    required this.regressionPrice,
    required this.priceRatio,
    required this.multiplier,
    required this.suggestedAmount,
    required this.zone,
    required this.marketStatus,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPrice': currentPrice,
      'regressionPrice': regressionPrice,
      'priceRatio': priceRatio,
      'multiplier': multiplier,
      'suggestedAmount': suggestedAmount,
      'zone': zone,
      'marketStatus': marketStatus,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory RainbowDCAResult.fromJson(Map<String, dynamic> json) {
    return RainbowDCAResult(
      currentPrice: json['currentPrice'],
      regressionPrice: json['regressionPrice'],
      priceRatio: json['priceRatio'],
      multiplier: json['multiplier'],
      suggestedAmount: json['suggestedAmount'],
      zone: json['zone'],
      marketStatus: json['marketStatus'],
      calculatedAt: DateTime.parse(json['calculatedAt']),
    );
  }
}
