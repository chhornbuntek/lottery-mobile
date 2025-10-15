import 'package:get/get.dart';
import '../api/លេខបិទ_api.dart';

class ClosingNumber {
  final int id;
  final String date;
  final String time;
  final String closingNumber;
  final double amountRiel;
  final double amountDollar;
  final double amountBaht;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClosingNumber({
    required this.id,
    required this.date,
    required this.time,
    required this.closingNumber,
    required this.amountRiel,
    required this.amountDollar,
    required this.amountBaht,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClosingNumber.fromJson(Map<String, dynamic> json) {
    return ClosingNumber(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      closingNumber: json['closing_number'] ?? '',
      amountRiel:
          double.tryParse(json['amount_riel']?.toString() ?? '0') ?? 0.0,
      amountDollar:
          double.tryParse(json['amount_dollar']?.toString() ?? '0') ?? 0.0,
      amountBaht:
          double.tryParse(json['amount_baht']?.toString() ?? '0') ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'closing_number': closingNumber,
      'amount_riel': amountRiel,
      'amount_dollar': amountDollar,
      'amount_baht': amountBaht,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ClosingNumbersService extends GetxController {
  final RxList<ClosingNumber> _closingNumbers = <ClosingNumber>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  List<ClosingNumber> get closingNumbers => _closingNumbers;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    loadClosingNumbers();
  }

  /// Load all closing numbers
  Future<void> loadClosingNumbers() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      print('🔄 ClosingNumbersService: Loading closing numbers...');

      final data = await ClosingNumbersApi.getClosingNumbers();
      _closingNumbers.value = data
          .map((json) => ClosingNumber.fromJson(json))
          .toList();

      print(
        '✅ ClosingNumbersService: Loaded ${_closingNumbers.length} closing numbers',
      );
    } catch (e) {
      _error.value = e.toString();
      print('❌ ClosingNumbersService Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load closing numbers by date
  Future<void> loadClosingNumbersByDate(String date) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      print(
        '🔄 ClosingNumbersService: Loading closing numbers for date: $date',
      );

      final data = await ClosingNumbersApi.getClosingNumbersByDate(date);
      _closingNumbers.value = data
          .map((json) => ClosingNumber.fromJson(json))
          .toList();

      print(
        '✅ ClosingNumbersService: Loaded ${_closingNumbers.length} closing numbers for $date',
      );
    } catch (e) {
      _error.value = e.toString();
      print('❌ ClosingNumbersService Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load closing numbers by time
  Future<void> loadClosingNumbersByTime(String time) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      print(
        '🔄 ClosingNumbersService: Loading closing numbers for time: $time',
      );

      final data = await ClosingNumbersApi.getClosingNumbersByTime(time);
      _closingNumbers.value = data
          .map((json) => ClosingNumber.fromJson(json))
          .toList();

      print(
        '✅ ClosingNumbersService: Loaded ${_closingNumbers.length} closing numbers for $time',
      );
    } catch (e) {
      _error.value = e.toString();
      print('❌ ClosingNumbersService Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load recent closing numbers
  Future<void> loadRecentClosingNumbers() async {
    try {
      _isLoading.value = true;
      _error.value = '';

      print('🔄 ClosingNumbersService: Loading recent closing numbers...');

      final data = await ClosingNumbersApi.getRecentClosingNumbers();
      _closingNumbers.value = data
          .map((json) => ClosingNumber.fromJson(json))
          .toList();

      print(
        '✅ ClosingNumbersService: Loaded ${_closingNumbers.length} recent closing numbers',
      );
    } catch (e) {
      _error.value = e.toString();
      print('❌ ClosingNumbersService Error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadClosingNumbers();
  }

  /// Get closing numbers grouped by date
  Map<String, List<ClosingNumber>> getClosingNumbersGroupedByDate() {
    final Map<String, List<ClosingNumber>> grouped = {};

    for (final closingNumber in _closingNumbers) {
      if (!grouped.containsKey(closingNumber.date)) {
        grouped[closingNumber.date] = [];
      }
      grouped[closingNumber.date]!.add(closingNumber);
    }

    return grouped;
  }

  /// Get closing numbers grouped by time
  Map<String, List<ClosingNumber>> getClosingNumbersGroupedByTime() {
    final Map<String, List<ClosingNumber>> grouped = {};

    for (final closingNumber in _closingNumbers) {
      if (!grouped.containsKey(closingNumber.time)) {
        grouped[closingNumber.time] = [];
      }
      grouped[closingNumber.time]!.add(closingNumber);
    }

    return grouped;
  }

  /// Format currency amount
  String formatCurrency(double amount, String currency) {
    if (amount == 0) return '';

    switch (currency.toLowerCase()) {
      case 'riel':
      case '៛':
        return '${amount.toStringAsFixed(0)}៛';
      case 'dollar':
      case 'usd':
      case '\$':
        return '\$${amount.toStringAsFixed(2)}';
      case 'baht':
      case 'thb':
        return '${amount.toStringAsFixed(2)}฿';
      default:
        return '${amount.toStringAsFixed(2)} $currency';
    }
  }
}
