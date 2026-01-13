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

  /// Get commission data with summary and time slots
  static Future<List<Map<String, dynamic>>> getCommissionDataWithTimeSlots({
    required DateTime date,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final dateStr = date.toIso8601String().split('T')[0];

      // Helper function to safely convert to int
      int _toInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      // Since Supabase doesn't support direct SQL execution, we'll break it down into multiple queries
      // Get agent data with lottery times
      final betsResponse = await _supabase
          .from('bets')
          .select('''
            id,
            lottery_time,
            total_amount,
            customer_name,
            lottery_time_id,
            lottery_times(sort_order)
          ''')
          .eq('user_id', user.id)
          .eq('bet_date', dateStr);

      // Get all bet IDs for this user and date first
      final userBetIds = betsResponse
          .map((bet) => _toInt(bet['id']))
          .where((id) => id > 0)
          .toList();

      // Get win data - filter by bet_ids that belong to the user
      final betResultsResponse = userBetIds.isEmpty
          ? <Map<String, dynamic>>[]
          : await _supabase
                .from('bet_results')
                .select('''
                bet_id,
                win_amount,
                date,
                lottery_time,
                bets!inner(
                  lottery_time,
                  user_id
                )
              ''')
                .eq('date', dateStr)
                .inFilter('bet_id', userBetIds);

      // Get commission data
      final commissionResponse = await _supabase
          .from('commissions')
          .select('total_commission_amount, total_win_amount')
          .eq('user_id', user.id)
          .eq('date', dateStr)
          .maybeSingle();

      // Process the data
      final List<Map<String, dynamic>> result = [];

      // Calculate summary
      int totalBets = 0;
      int customerBets = 0;
      int agentBets = 0;
      Map<String, Map<String, dynamic>> timeSlotData = {};

      for (var bet in betsResponse) {
        final totalAmount = _toInt(bet['total_amount']);
        final customerName = bet['customer_name'] as String? ?? '';
        final lotteryTime = bet['lottery_time'] as String? ?? '';
        final lotteryTimes = bet['lottery_times'];
        int sortOrder = 0;
        if (lotteryTimes != null) {
          if (lotteryTimes is List && lotteryTimes.isNotEmpty) {
            final firstItem = lotteryTimes[0] as Map<String, dynamic>?;
            sortOrder = _toInt(firstItem?['sort_order']);
          } else if (lotteryTimes is Map<String, dynamic>) {
            sortOrder = _toInt(lotteryTimes['sort_order']);
          }
        }

        totalBets += totalAmount;

        if (customerName.isEmpty) {
          agentBets += totalAmount;
        } else {
          customerBets += totalAmount;
        }

        // Group by lottery time
        if (lotteryTime.isNotEmpty) {
          if (!timeSlotData.containsKey(lotteryTime)) {
            timeSlotData[lotteryTime] = {
              'lottery_time': lotteryTime,
              'sort_order': sortOrder,
              'total_bets': 0,
              'customer_bets': 0,
              'agent_bets': 0,
              'total_payout': 0,
            };
          }
          timeSlotData[lotteryTime]!['total_bets'] =
              _toInt(timeSlotData[lotteryTime]!['total_bets']) + totalAmount;
          if (customerName.isEmpty) {
            timeSlotData[lotteryTime]!['agent_bets'] =
                _toInt(timeSlotData[lotteryTime]!['agent_bets']) + totalAmount;
          } else {
            timeSlotData[lotteryTime]!['customer_bets'] =
                _toInt(timeSlotData[lotteryTime]!['customer_bets']) +
                totalAmount;
          }
        }
      }

      // Add win amounts - now filtered by user_id
      for (var result in betResultsResponse) {
        // Try to get lottery_time from bet_results first, then from bets
        String lotteryTime = result['lottery_time'] as String? ?? '';
        if (lotteryTime.isEmpty) {
          final bet = result['bets'] as Map<String, dynamic>?;
          if (bet != null) {
            lotteryTime = bet['lottery_time'] as String? ?? '';
          }
        }

        final winAmount = _toInt(result['win_amount']);
        if (lotteryTime.isNotEmpty && timeSlotData.containsKey(lotteryTime)) {
          timeSlotData[lotteryTime]!['total_payout'] =
              _toInt(timeSlotData[lotteryTime]!['total_payout']) + winAmount;
        }
      }

      // Calculate win/loss for time slots
      for (var key in timeSlotData.keys) {
        final data = timeSlotData[key]!;
        data['win_loss'] =
            _toInt(data['total_bets']) - _toInt(data['total_payout']);
      }

      // Add summary
      final bonus = _toInt(commissionResponse?['total_commission_amount']);
      final totalPayout = _toInt(commissionResponse?['total_win_amount']);
      final winLoss = totalBets - totalPayout;

      result.add({
        'type': 'summary',
        'lottery_time': null,
        'sort_order': null,
        'bonus': bonus,
        'total_bets': totalBets,
        'customer_bets': customerBets,
        'agent_bets': agentBets,
        'total_payout': totalPayout,
        'win_loss': winLoss,
      });

      // Add time slots
      final timeSlotList = timeSlotData.values.toList();
      timeSlotList.sort(
        (a, b) => _toInt(a['sort_order']).compareTo(_toInt(b['sort_order'])),
      );

      for (var slot in timeSlotList) {
        result.add({
          'type': 'timeslot',
          'lottery_time': slot['lottery_time'],
          'sort_order': slot['sort_order'],
          'bonus': 0,
          'total_bets': slot['total_bets'],
          'customer_bets': slot['customer_bets'],
          'agent_bets': slot['agent_bets'],
          'total_payout': slot['total_payout'],
          'win_loss': slot['win_loss'],
        });
      }

      return result;
    } catch (e) {
      print('Error fetching commission data with time slots: $e');
      throw Exception('Failed to fetch commission data: $e');
    }
  }
}
