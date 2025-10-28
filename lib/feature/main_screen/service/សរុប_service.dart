import '../api/សរុប_api.dart';

class LotteryTimeTotal {
  final int? id;
  final String userId;
  final DateTime date;
  final int lotteryTimeId;
  final String lotteryTimeName;
  final int totalAmount;
  final int betCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  LotteryTimeTotal({
    this.id,
    required this.userId,
    required this.date,
    required this.lotteryTimeId,
    required this.lotteryTimeName,
    required this.totalAmount,
    required this.betCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LotteryTimeTotal.fromMap(Map<String, dynamic> map) {
    return LotteryTimeTotal(
      id: map['id'],
      userId: map['user_id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      lotteryTimeId: map['lottery_time_id'] ?? 0,
      lotteryTimeName: map['lottery_time_name'] ?? '',
      totalAmount: map['total_amount'] ?? 0,
      betCount: map['bet_count'] ?? 0,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'lottery_time_id': lotteryTimeId,
      'lottery_time_name': lotteryTimeName,
      'total_amount': totalAmount,
      'bet_count': betCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'LotteryTimeTotal(id: $id, date: $date, lotteryTimeName: $lotteryTimeName, totalAmount: $totalAmount, betCount: $betCount)';
  }
}

class LotteryTimeWithTotal {
  final int id;
  final String timeName;
  final String timeCategory;
  final int sortOrder;
  final bool isActive;
  final int totalAmount;
  final int betCount;

  LotteryTimeWithTotal({
    required this.id,
    required this.timeName,
    required this.timeCategory,
    required this.sortOrder,
    required this.isActive,
    required this.totalAmount,
    required this.betCount,
  });

  factory LotteryTimeWithTotal.fromMap(Map<String, dynamic> map) {
    return LotteryTimeWithTotal(
      id: map['id'] ?? 0,
      timeName: map['time_name'] ?? '',
      timeCategory: map['time_category'] ?? '',
      sortOrder: map['sort_order'] ?? 0,
      isActive: map['is_active'] ?? false,
      totalAmount: map['total_amount'] ?? 0,
      betCount: map['bet_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time_name': timeName,
      'time_category': timeCategory,
      'sort_order': sortOrder,
      'is_active': isActive,
      'total_amount': totalAmount,
      'bet_count': betCount,
    };
  }

  @override
  String toString() {
    return 'LotteryTimeWithTotal(id: $id, timeName: $timeName, totalAmount: $totalAmount, betCount: $betCount)';
  }
}

class DateSummary {
  final String date;
  final int totalAmount;
  final int totalBetCount;
  final int lotteryTimeCount;

  DateSummary({
    required this.date,
    required this.totalAmount,
    required this.totalBetCount,
    required this.lotteryTimeCount,
  });

  factory DateSummary.fromMap(Map<String, dynamic> map) {
    return DateSummary(
      date: map['date'] ?? '',
      totalAmount: map['total_amount'] ?? 0,
      totalBetCount: map['total_bet_count'] ?? 0,
      lotteryTimeCount: map['lottery_time_count'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'DateSummary(date: $date, totalAmount: $totalAmount, totalBetCount: $totalBetCount)';
  }
}

class LotteryTotalsService {
  /// Get lottery time totals for a specific date
  static Future<List<LotteryTimeTotal>> getLotteryTimeTotalsByDate({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final data = await LotteryTotalsApi.getLotteryTimeTotalsByDate(
        date: date,
        userId: userId,
      );

      return data.map((item) => LotteryTimeTotal.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching lottery time totals by date: $e');
      throw Exception('Failed to get lottery time totals by date: $e');
    }
  }

  /// Get lottery time totals for a date range
  static Future<List<LotteryTimeTotal>> getLotteryTimeTotalsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      final data = await LotteryTotalsApi.getLotteryTimeTotalsByDateRange(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      );

      return data.map((item) => LotteryTimeTotal.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching lottery time totals by date range: $e');
      throw Exception('Failed to get lottery time totals by date range: $e');
    }
  }

  /// Get summary for a specific date
  static Future<DateSummary> getDateSummary({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final data = await LotteryTotalsApi.getDateSummary(
        date: date,
        userId: userId,
      );

      return DateSummary.fromMap(data);
    } catch (e) {
      print('Error fetching date summary: $e');
      throw Exception('Failed to get date summary: $e');
    }
  }

  /// Get all lottery times with their totals for a specific date
  static Future<List<LotteryTimeWithTotal>> getAllLotteryTimesWithTotals({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final data = await LotteryTotalsApi.getAllLotteryTimesWithTotals(
        date: date,
        userId: userId,
      );

      return data.map((item) => LotteryTimeWithTotal.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching lottery times with totals: $e');
      throw Exception('Failed to get lottery times with totals: $e');
    }
  }

  /// Manually recalculate totals for a specific date
  static Future<void> recalculateTotalsForDate({
    required DateTime date,
    String? userId,
  }) async {
    try {
      await LotteryTotalsApi.recalculateTotalsForDate(
        date: date,
        userId: userId,
      );
    } catch (e) {
      print('Error recalculating totals: $e');
      throw Exception('Failed to recalculate totals: $e');
    }
  }

  /// Format amount for display
  static String formatAmount(int amount) {
    return '$amount ៛';
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get lottery time totals grouped by category
  static Future<Map<String, List<LotteryTimeWithTotal>>>
  getLotteryTimesGroupedByCategory({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final lotteryTimes = await getAllLotteryTimesWithTotals(
        date: date,
        userId: userId,
      );

      final grouped = <String, List<LotteryTimeWithTotal>>{};
      for (var lotteryTime in lotteryTimes) {
        if (!grouped.containsKey(lotteryTime.timeCategory)) {
          grouped[lotteryTime.timeCategory] = [];
        }
        grouped[lotteryTime.timeCategory]!.add(lotteryTime);
      }

      return grouped;
    } catch (e) {
      print('Error grouping lottery times by category: $e');
      throw Exception('Failed to group lottery times by category: $e');
    }
  }
}
