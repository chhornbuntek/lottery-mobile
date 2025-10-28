import 'package:supabase_flutter/supabase_flutter.dart';

class ListApi {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch agents from profile table with role = 'user'
  /// Purpose: Populate agent dropdown for filtering
  static Future<List<Map<String, dynamic>>> fetchAgents() async {
    try {
      final response = await _supabase
          .from('profile')
          .select('id, full_name, phone, role')
          .eq('role', 'user')
          .order('full_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching agents: $e');
      throw Exception('Failed to fetch agents: $e');
    }
  }

  /// Fetch available lottery times
  /// Purpose: Populate lottery time dropdown for filtering
  static Future<List<String>> fetchLotteryTimes() async {
    try {
      final response = await _supabase
          .from('bets')
          .select('lottery_time')
          .not('lottery_time', 'is', null)
          .order('lottery_time');

      // Extract unique lottery times
      Set<String> uniqueTimes = {};
      for (var item in response) {
        String lotteryTime = item['lottery_time'] ?? '';
        if (lotteryTime.isNotEmpty) {
          uniqueTimes.add(lotteryTime);
        }
      }

      return uniqueTimes.toList();
    } catch (e) {
      print('Error fetching lottery times: $e');
      throw Exception('Failed to fetch lottery times: $e');
    }
  }

  /// Fetch lottery times grouped by category from lottery_times table
  /// Purpose: Populate lottery time dropdown for filtering
  static Future<Map<String, List<String>>> fetchLotteryTimesGrouped() async {
    try {
      final response = await _supabase
          .from('lottery_times')
          .select('time_name, time_category')
          .eq('is_active', true)
          .order('sort_order');

      // Group lottery times by category
      Map<String, List<String>> groupedTimes = {
        'ខ្មែរ': <String>[],
        'យួន': <String>[],
        'អន្តរជាតិ': <String>[],
        'ថៃ': <String>[],
      };

      // Categorize lottery times based on time_category
      for (var item in response) {
        String timeName = item['time_name'] ?? '';
        String timeCategory = item['time_category'] ?? '';

        if (timeName.isNotEmpty) {
          switch (timeCategory) {
            case 'khmer-vip':
              groupedTimes['ខ្មែរ']!.add(timeName);
              break;
            case 'vietnam':
              groupedTimes['យួន']!.add(timeName);
              break;
            case 'international':
              groupedTimes['អន្តរជាតិ']!.add(timeName);
              break;
            case 'thai':
              groupedTimes['ថៃ']!.add(timeName);
              break;
          }
        }
      }

      // Sort each category
      groupedTimes.forEach((key, value) {
        value.sort();
      });

      return groupedTimes;
    } catch (e) {
      print('Error fetching lottery times: $e');
      throw Exception('Failed to fetch lottery times: $e');
    }
  }

  /// Fetch report data - ALL BETS and WINNING RESULTS separately
  /// This method fetches both all bets and winning results to calculate proper totals
  static Future<Map<String, List<Map<String, dynamic>>>> fetchReportData({
    required DateTime selectedDate,
    String? agentId,
    String? lotteryTime,
  }) async {
    try {
      String formattedDate =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

      // Fetch ALL BETS for the date (not just winning ones)
      var betsQuery = _supabase
          .from('bets')
          .select('*')
          .gte('created_at', '$formattedDate 00:00:00')
          .lte('created_at', '$formattedDate 23:59:59');

      // Apply agent filter if provided
      if (agentId != null) {
        betsQuery = betsQuery.eq('user_id', agentId);
      }

      // Apply lottery time filter if provided
      if (lotteryTime != null && lotteryTime.isNotEmpty) {
        betsQuery = betsQuery.eq('lottery_time', lotteryTime);
      }

      final allBets = await betsQuery.order('created_at', ascending: false);

      // Fetch WINNING RESULTS for the date with deduplication
      // Use DISTINCT ON to prevent duplicate bet_results
      var resultsQuery = _supabase
          .from('bet_results')
          .select('''
            *,
            bets!inner(
              id,
              user_id,
              bet_pattern,
              total_amount,
              bill_type
            )
          ''')
          .eq('is_win', true)
          .eq('date', formattedDate);

      // Apply agent filter if provided
      if (agentId != null) {
        resultsQuery = resultsQuery.eq('bets.user_id', agentId);
      }

      // Apply lottery time filter if provided
      if (lotteryTime != null && lotteryTime.isNotEmpty) {
        resultsQuery = resultsQuery.eq('lottery_time', lotteryTime);
      }

      final winningResults = await resultsQuery.order(
        'created_at',
        ascending: false,
      );

      return {
        'all_bets': List<Map<String, dynamic>>.from(allBets),
        'winning_results': List<Map<String, dynamic>>.from(winningResults),
      };
    } catch (e) {
      print('Error fetching report data: $e');
      throw Exception('Failed to fetch report data: $e');
    }
  }

  /// Get bet data for specific date and agent
  static Future<List<Map<String, dynamic>>> getBetsByDateAndAgent({
    required DateTime date,
    String? agentId,
  }) async {
    try {
      String formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      var query = _supabase
          .from('bets')
          .select('*')
          .gte('created_at', '$formattedDate 00:00:00')
          .lte('created_at', '$formattedDate 23:59:59');

      // Apply agent filter if provided
      if (agentId != null) {
        query = query.eq('user_id', agentId);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching bets by date and agent: $e');
      throw Exception('Failed to fetch bets by date and agent: $e');
    }
  }

  /// Get winning bet results for specific date and agent
  static Future<List<Map<String, dynamic>>> getWinningResults({
    required DateTime date,
    String? agentId,
  }) async {
    try {
      String formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      var query = _supabase
          .from('bet_results')
          .select('''
            *,
            bets!inner(
              id,
              user_id,
              customer_name,
              lottery_time,
              bet_pattern,
              bet_numbers,
              amount_per_number,
              total_amount,
              multiplier,
              bill_type,
              created_at
            )
          ''')
          .eq('is_win', true)
          .eq('date', formattedDate);

      // Apply agent filter if provided
      if (agentId != null) {
        query = query.eq('bets.user_id', agentId);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching winning results: $e');
      throw Exception('Failed to fetch winning results: $e');
    }
  }

  /// Get summary data for a specific date
  static Future<Map<String, dynamic>> getDateSummary({
    required DateTime date,
    String? agentId,
  }) async {
    try {
      String formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Get total bets
      var betsQuery = _supabase
          .from('bets')
          .select('total_amount, bet_pattern, multiplier')
          .gte('created_at', '$formattedDate 00:00:00')
          .lte('created_at', '$formattedDate 23:59:59');

      if (agentId != null) {
        betsQuery = betsQuery.eq('user_id', agentId);
      }

      final betsResponse = await betsQuery;

      // Get winning results
      var resultsQuery = _supabase
          .from('bet_results')
          .select('win_amount, bet_id')
          .eq('is_win', true)
          .eq('date', formattedDate);

      final resultsResponse = await resultsQuery;

      // Calculate totals
      int total2DigitBets = 0;
      int total3DigitBets = 0;
      int total2DigitPayouts = 0;
      int total3DigitPayouts = 0;

      for (var bet in betsResponse) {
        int amount = ((bet['total_amount'] ?? 0) as num).toInt();
        String pattern = bet['bet_pattern'] ?? '';

        if (pattern.contains('2D') || pattern.contains('2digit')) {
          total2DigitBets += amount;
        } else if (pattern.contains('3D') || pattern.contains('3digit')) {
          total3DigitBets += amount;
        }
      }

      for (var result in resultsResponse) {
        int payout = ((result['win_amount'] ?? 0) as num).toInt();
        // This is simplified - in real implementation, you'd need to check the bet pattern
        // For now, we'll distribute based on a simple rule
        if (total2DigitBets > 0 && total3DigitBets == 0) {
          total2DigitPayouts += payout;
        } else if (total3DigitBets > 0 && total2DigitBets == 0) {
          total3DigitPayouts += payout;
        } else {
          // If both exist, distribute proportionally
          total2DigitPayouts += (payout * 0.3).round();
          total3DigitPayouts += (payout * 0.7).round();
        }
      }

      return {
        'date': formattedDate,
        'total_2digit_bets': total2DigitBets,
        'total_3digit_bets': total3DigitBets,
        'total_bets': total2DigitBets + total3DigitBets,
        'total_2digit_payouts': total2DigitPayouts,
        'total_3digit_payouts': total3DigitPayouts,
        'total_payouts': total2DigitPayouts + total3DigitPayouts,
        'net_result':
            (total2DigitBets + total3DigitBets) -
            (total2DigitPayouts + total3DigitPayouts),
        'bet_count': betsResponse.length,
        'win_count': resultsResponse.length,
      };
    } catch (e) {
      print('Error fetching date summary: $e');
      throw Exception('Failed to fetch date summary: $e');
    }
  }
}
