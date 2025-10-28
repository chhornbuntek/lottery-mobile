import 'package:supabase_flutter/supabase_flutter.dart';

class LotteryTotalsApi {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get lottery time totals for a specific user and date
  static Future<List<Map<String, dynamic>>> getLotteryTimeTotalsByDate({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('lottery_time_totals')
          .select('''
            *,
            lottery_times!inner(
              id,
              time_name,
              time_category,
              sort_order
            )
          ''')
          .eq('user_id', targetUserId)
          .eq('date', dateStr)
          .order('lottery_times(sort_order)', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch lottery time totals: $e');
    }
  }

  /// Get lottery time totals for a date range
  static Future<List<Map<String, dynamic>>> getLotteryTimeTotalsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('lottery_time_totals')
          .select('''
            *,
            lottery_times!inner(
              id,
              time_name,
              time_category,
              sort_order
            )
          ''')
          .eq('user_id', targetUserId)
          .gte('date', startDateStr)
          .lte('date', endDateStr)
          .order('date', ascending: false)
          .order('lottery_times(sort_order)', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch lottery time totals by date range: $e');
    }
  }

  /// Get summary totals for a specific date
  static Future<Map<String, dynamic>> getDateSummary({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('lottery_time_totals')
          .select('total_amount, bet_count')
          .eq('user_id', targetUserId)
          .eq('date', dateStr);

      int totalAmount = 0;
      int totalBetCount = 0;

      for (var record in response) {
        totalAmount += (record['total_amount'] ?? 0) as int;
        totalBetCount += (record['bet_count'] ?? 0) as int;
      }

      return {
        'date': dateStr,
        'total_amount': totalAmount,
        'total_bet_count': totalBetCount,
        'lottery_time_count': response.length,
      };
    } catch (e) {
      throw Exception('Failed to fetch date summary: $e');
    }
  }

  /// Get all lottery times with their totals for a specific date
  static Future<List<Map<String, dynamic>>> getAllLotteryTimesWithTotals({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      final dateStr = date.toIso8601String().split('T')[0];

      // Get all active lottery times
      final lotteryTimesResponse = await _supabase
          .from('lottery_times')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      // Get totals for the specific user and date
      final totalsResponse = await _supabase
          .from('lottery_time_totals')
          .select('lottery_time_id, total_amount, bet_count')
          .eq('user_id', targetUserId)
          .eq('date', dateStr);

      // Create a map of lottery_time_id to totals
      final totalsMap = <int, Map<String, dynamic>>{};
      for (var total in totalsResponse) {
        totalsMap[total['lottery_time_id'] as int] = {
          'total_amount': total['total_amount'] ?? 0,
          'bet_count': total['bet_count'] ?? 0,
        };
      }

      // Combine ALL lottery times with their totals (including 0 totals)
      final result = <Map<String, dynamic>>[];
      for (var lotteryTime in lotteryTimesResponse) {
        final lotteryTimeId = lotteryTime['id'] as int;
        final totals =
            totalsMap[lotteryTimeId] ?? {'total_amount': 0, 'bet_count': 0};

        result.add({
          'id': lotteryTime['id'],
          'time_name': lotteryTime['time_name'],
          'time_category': lotteryTime['time_category'],
          'sort_order': lotteryTime['sort_order'],
          'is_active': lotteryTime['is_active'],
          'total_amount': totals['total_amount'],
          'bet_count': totals['bet_count'],
        });
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch lottery times with totals: $e');
    }
  }

  /// Manually recalculate totals for a specific user and date
  static Future<void> recalculateTotalsForDate({
    required DateTime date,
    String? userId,
  }) async {
    try {
      final targetUserId = userId ?? _supabase.auth.currentUser?.id;
      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      final dateStr = date.toIso8601String().split('T')[0];

      // Delete existing totals for the date
      await _supabase
          .from('lottery_time_totals')
          .delete()
          .eq('user_id', targetUserId)
          .eq('date', dateStr);

      // Get all bets for the date and recalculate
      final betsResponse = await _supabase
          .from('bets')
          .select('lottery_time_id, lottery_time, total_amount')
          .eq('user_id', targetUserId)
          .eq('bet_date', dateStr);

      // Group by lottery_time_id and calculate totals
      final totalsMap = <int, Map<String, dynamic>>{};
      for (var bet in betsResponse) {
        final lotteryTimeId = bet['lottery_time_id'] as int;
        final lotteryTimeName = bet['lottery_time'] as String;
        final amount = bet['total_amount'] as int;

        if (!totalsMap.containsKey(lotteryTimeId)) {
          totalsMap[lotteryTimeId] = {
            'lottery_time_name': lotteryTimeName,
            'total_amount': 0,
            'bet_count': 0,
          };
        }

        totalsMap[lotteryTimeId]!['total_amount'] += amount;
        totalsMap[lotteryTimeId]!['bet_count'] += 1;
      }

      // Get user's admin_id from profile
      final profileResponse = await _supabase
          .from('profile')
          .select('admin_id')
          .eq('id', targetUserId)
          .single();

      final adminId = profileResponse['admin_id'] as String?;

      // Insert recalculated totals
      for (var entry in totalsMap.entries) {
        await _supabase.from('lottery_time_totals').insert({
          'user_id': targetUserId,
          'date': dateStr,
          'lottery_time_id': entry.key,
          'lottery_time_name': entry.value['lottery_time_name'],
          'total_amount': entry.value['total_amount'],
          'bet_count': entry.value['bet_count'],
          'admin_id': adminId, // Auto-populate admin_id
        });
      }
    } catch (e) {
      throw Exception('Failed to recalculate totals: $e');
    }
  }
}
