import 'package:supabase_flutter/supabase_flutter.dart';

class CommissionsApi {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Insert or update daily commission record
  static Future<Map<String, dynamic>> upsertDailyCommission({
    required DateTime date,
    required int totalBetAmount,
    required int betCount,
    double commissionRate = 0.0, // No commission - set to 0%
    int totalWinAmount = 0,
    int totalLossAmount = 0,
    int netProfit = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user's admin_id from profile
      final profileResponse = await _supabase
          .from('profile')
          .select('admin_id')
          .eq('id', user.id)
          .single();

      final adminId = profileResponse['admin_id'] as String?;

      final commissionAmount = (totalBetAmount * commissionRate / 100).round();

      final response = await _supabase
          .from('commissions')
          .upsert({
            'user_id': user.id,
            'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
            'total_bet_amount': totalBetAmount,
            'total_commission_amount': commissionAmount,
            'commission_rate': commissionRate,
            'bet_count': betCount,
            'total_win_amount': totalWinAmount,
            'total_loss_amount': totalLossAmount,
            'net_profit': netProfit,
            'admin_id': adminId, // Auto-populate admin_id
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to upsert daily commission: $e');
    }
  }

  /// Get user's commissions (simplified - no date filtering for now)
  static Future<List<Map<String, dynamic>>> getUserCommissions({
    int? limit,
    int? offset,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabase
          .from('commissions')
          .select('*')
          .eq('user_id', user.id)
          .order('date', ascending: false);

      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user commissions: $e');
    }
  }

  /// Get commission summary (simplified - last 30 days)
  static Future<Map<String, dynamic>> getCommissionSummary() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('commissions')
          .select('total_bet_amount, total_commission_amount, bet_count')
          .eq('user_id', user.id);

      // Calculate totals
      int totalBetAmount = 0;
      int totalCommissionAmount = 0;
      int totalBetCount = 0;

      for (var record in response) {
        totalBetAmount += (record['total_bet_amount'] ?? 0) as int;
        totalCommissionAmount +=
            (record['total_commission_amount'] ?? 0) as int;
        totalBetCount += (record['bet_count'] ?? 0) as int;
      }

      // Get count of unique agents (users) who placed bets
      final uniqueAgentsResponse = await _supabase
          .from('commissions')
          .select('user_id')
          .neq('user_id', user.id); // Exclude current user

      int uniqueAgentCount = uniqueAgentsResponse.length;

      return {
        'total_bet_amount': totalBetAmount,
        'total_commission_amount': totalCommissionAmount,
        'total_bet_count': totalBetCount,
        'unique_agent_count': uniqueAgentCount,
        'average_commission_rate': totalBetAmount > 0
            ? (totalCommissionAmount / totalBetAmount * 100).toStringAsFixed(2)
            : '0.00',
      };
    } catch (e) {
      throw Exception('Failed to fetch commission summary: $e');
    }
  }

  /// Get today's commission record
  static Future<Map<String, dynamic>?> getTodayCommission() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase
          .from('commissions')
          .select('*')
          .eq('user_id', user.id)
          .eq('date', today)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch today commission: $e');
    }
  }

  /// Delete commission record
  static Future<void> deleteCommission(int commissionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('commissions')
          .delete()
          .eq('id', commissionId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete commission: $e');
    }
  }
}
