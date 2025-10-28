import '../api/កម្រៃ_api.dart';

class CommissionData {
  final int? id;
  final String userId;
  final DateTime date;
  final int totalBetAmount;
  final int totalCommissionAmount;
  final double commissionRate;
  final int betCount;
  final int totalWinAmount;
  final int totalLossAmount;
  final int netProfit;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommissionData({
    this.id,
    required this.userId,
    required this.date,
    required this.totalBetAmount,
    required this.totalCommissionAmount,
    required this.commissionRate,
    required this.betCount,
    required this.totalWinAmount,
    required this.totalLossAmount,
    required this.netProfit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommissionData.fromMap(Map<String, dynamic> map) {
    return CommissionData(
      id: map['id'],
      userId: map['user_id'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      totalBetAmount: map['total_bet_amount'] ?? 0,
      totalCommissionAmount: map['total_commission_amount'] ?? 0,
      commissionRate: (map['commission_rate'] ?? 0.0).toDouble(),
      betCount: map['bet_count'] ?? 0,
      totalWinAmount: map['total_win_amount'] ?? 0,
      totalLossAmount: map['total_loss_amount'] ?? 0,
      netProfit: map['net_profit'] ?? 0,
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
      'total_bet_amount': totalBetAmount,
      'total_commission_amount': totalCommissionAmount,
      'commission_rate': commissionRate,
      'bet_count': betCount,
      'total_win_amount': totalWinAmount,
      'total_loss_amount': totalLossAmount,
      'net_profit': netProfit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CommissionData(id: $id, date: $date, totalBetAmount: $totalBetAmount, totalCommissionAmount: $totalCommissionAmount)';
  }
}

class CommissionSummary {
  final int totalBetAmount;
  final int totalCommissionAmount;
  final int totalBetCount;
  final int uniqueAgentCount;
  final String averageCommissionRate;

  CommissionSummary({
    required this.totalBetAmount,
    required this.totalCommissionAmount,
    required this.totalBetCount,
    required this.uniqueAgentCount,
    required this.averageCommissionRate,
  });

  factory CommissionSummary.fromMap(Map<String, dynamic> map) {
    return CommissionSummary(
      totalBetAmount: map['total_bet_amount'] ?? 0,
      totalCommissionAmount: map['total_commission_amount'] ?? 0,
      totalBetCount: map['total_bet_count'] ?? 0,
      uniqueAgentCount: map['unique_agent_count'] ?? 0,
      averageCommissionRate: map['average_commission_rate'] ?? '0.00',
    );
  }
}

class CommissionsService {
  /// Upsert daily commission record
  static Future<CommissionData> upsertDailyCommission({
    required DateTime date,
    required int totalBetAmount,
    required int betCount,
    double commissionRate = 0.0, // No commission - set to 0%
    int totalWinAmount = 0,
    int totalLossAmount = 0,
    int netProfit = 0,
  }) async {
    try {
      final response = await CommissionsApi.upsertDailyCommission(
        date: date,
        totalBetAmount: totalBetAmount,
        betCount: betCount,
        commissionRate: commissionRate,
        totalWinAmount: totalWinAmount,
        totalLossAmount: totalLossAmount,
        netProfit: netProfit,
      );

      return CommissionData.fromMap(response);
    } catch (e) {
      print('Error upserting daily commission: $e');
      throw Exception('Failed to upsert daily commission: $e');
    }
  }

  /// Get user's commissions (simplified)
  static Future<List<CommissionData>> getUserCommissions({
    int? limit,
    int? offset,
  }) async {
    try {
      final data = await CommissionsApi.getUserCommissions(
        limit: limit,
        offset: offset,
      );

      return data.map((item) => CommissionData.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching user commissions: $e');
      throw Exception('Failed to get user commissions: $e');
    }
  }

  /// Get commission summary (simplified - last 30 days)
  static Future<CommissionSummary> getCommissionSummary() async {
    try {
      final data = await CommissionsApi.getCommissionSummary();
      return CommissionSummary.fromMap(data);
    } catch (e) {
      print('Error fetching commission summary: $e');
      throw Exception('Failed to get commission summary: $e');
    }
  }

  /// Get today's commission record
  static Future<CommissionData?> getTodayCommission() async {
    try {
      final data = await CommissionsApi.getTodayCommission();

      if (data == null) return null;
      return CommissionData.fromMap(data);
    } catch (e) {
      print('Error fetching today commission: $e');
      throw Exception('Failed to get today commission: $e');
    }
  }

  /// Delete commission record
  static Future<void> deleteCommission(int commissionId) async {
    try {
      await CommissionsApi.deleteCommission(commissionId);
    } catch (e) {
      print('Error deleting commission: $e');
      throw Exception('Failed to delete commission: $e');
    }
  }

  /// Calculate commission from bet amount
  static int calculateCommission(int betAmount, double commissionRate) {
    return (betAmount * commissionRate / 100).round();
  }

  /// Format commission rate for display
  static String formatCommissionRate(double rate) {
    return '${rate.toStringAsFixed(2)}%';
  }

  /// Format amount for display
  static String formatAmount(int amount) {
    return '$amount ៛';
  }

  /// Get commission statistics for dashboard (simplified)
  static Future<Map<String, dynamic>> getCommissionStats() async {
    try {
      final summary = await getCommissionSummary();
      final commissions = await getUserCommissions();

      return {
        'summary': summary,
        'commissions': commissions,
        'total_days': 30, // Last 30 days
        'average_daily_bet': commissions.isNotEmpty
            ? (summary.totalBetAmount / commissions.length).round()
            : 0,
        'average_daily_commission': commissions.isNotEmpty
            ? (summary.totalCommissionAmount / commissions.length).round()
            : 0,
      };
    } catch (e) {
      print('Error fetching commission stats: $e');
      throw Exception('Failed to get commission stats: $e');
    }
  }
}
