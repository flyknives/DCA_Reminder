import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/btc_data.dart';
import '../services/storage_service.dart';
import '../models/investment_record.dart';

enum KlineLoadingState { initial, loading, loaded, error }

class KlineChartProvider extends ChangeNotifier {
  final APIService _apiService;
  late StorageService _storageService;

  List<HistoricalData> _klineData = [];
  List<InvestmentRecord> _investmentRecords = [];
  double _averageCost = 0.0;
  KlineLoadingState _loadingState = KlineLoadingState.initial;
  String? _errorMessage;
  String _selectedInterval = '1d'; // Default interval

  KlineChartProvider(this._apiService) {
    _initialize();
  }

  Future<void> _initialize() async {
    _storageService = await StorageService.getInstance();
    await _fetchInvestmentData();
  }

  // Getters
  List<HistoricalData> get klineData => _klineData;
  List<InvestmentRecord> get investmentRecords => _investmentRecords;
  double get averageCost => _averageCost;
  KlineLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  String get selectedInterval => _selectedInterval;

  /// Fetch K-line data
  Future<void> fetchKlineData({String interval = '1d', int limit = 200}) async {
    if (_loadingState == KlineLoadingState.loading && _selectedInterval == interval) return; // Prevent duplicate fetches

    _setLoadingState(KlineLoadingState.loading);
    _selectedInterval = interval;
    notifyListeners(); // Notify listeners about interval change

    try {
      _klineData = await _apiService.getHistoricalData(
        interval: interval,
        limit: limit,
      );
      await _fetchInvestmentData(); // Fetch investment data after kline data
      _setLoadingState(KlineLoadingState.loaded);
    } catch (e) {
      debugPrint('Error fetching K-line data: $e');
      _setErrorState('加载K线数据失败: $e');
    }
  }

  /// Fetch investment data and calculate average cost
  Future<void> _fetchInvestmentData() async {
    _investmentRecords = await _storageService.getInvestmentRecords();
    if (_investmentRecords.isNotEmpty) {
      final totalInvested = _investmentRecords.fold<double>(0, (sum, record) => sum + record.amount);
      final totalBTCAmount = _investmentRecords.fold<double>(0, (sum, record) => sum + record.btcAmount);
      _averageCost = totalInvested / totalBTCAmount;
    } else {
      _averageCost = 0.0;
    }
    notifyListeners();
  }

  /// Set loading state
  void _setLoadingState(KlineLoadingState state) {
    _loadingState = state;
    if (state != KlineLoadingState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Set error state
  void _setErrorState(String message) {
    _loadingState = KlineLoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Change interval and refetch data
  Future<void> changeInterval(String newInterval) async {
    if (_selectedInterval == newInterval) return;
    _selectedInterval = newInterval;
    await fetchKlineData(interval: newInterval);
  }
}
