import 'package:supabase_flutter/supabase_flutter.dart';

class LotteryTimesApi {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all active lottery times from the database
  static Future<List<Map<String, dynamic>>> getLotteryTimes() async {
    try {
      final response = await _supabase
          .from('lottery_times')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch lottery times: $e');
    }
  }

  /// Fetch lottery times by category
  static Future<List<Map<String, dynamic>>> getLotteryTimesByCategory(
    String category,
  ) async {
    try {
      final response = await _supabase
          .from('lottery_times')
          .select()
          .eq('is_active', true)
          .eq('time_category', category)
          .order('sort_order');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch lottery times by category: $e');
    }
  }
}

class BetsApi {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ========== PENDING BETS METHODS ==========

  /// Insert a pending bet (when user clicks "ចាក់ថ្មី")
  static Future<Map<String, dynamic>> insertPendingBet({
    required String customerName,
    required int lotteryTimeId,
    required String lotteryTime,
    required String betPattern,
    required List<String> betNumbers,
    required int amountPerNumber,
    required int totalAmount,
    required int multiplier,
    required String billType,
    required List<String> selectedConditions,
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

      final response = await _supabase
          .from('pending_bets')
          .insert({
            'customer_name': customerName,
            'lottery_time_id': lotteryTimeId,
            'lottery_time': lotteryTime,
            'bet_pattern': betPattern,
            'bet_numbers': betNumbers,
            'amount_per_number': amountPerNumber,
            'total_amount': totalAmount,
            'multiplier': multiplier,
            'bill_type': billType,
            'selected_conditions': selectedConditions,
            'bet_date': DateTime.now().toIso8601String().split(
              'T',
            )[0], // Current date
            'user_id': user.id,
            'admin_id': adminId, // Auto-populate admin_id
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to insert pending bet: $e');
    }
  }

  /// Insert multiple pending bets (batch operation)
  static Future<List<Map<String, dynamic>>> insertPendingBets(
    List<Map<String, dynamic>> pendingBetsData,
  ) async {
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

      // Add user_id and admin_id to all pending bets
      for (var bet in pendingBetsData) {
        bet['user_id'] = user.id;
        bet['admin_id'] = adminId; // Auto-populate admin_id
      }

      final response = await _supabase
          .from('pending_bets')
          .insert(pendingBetsData)
          .select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to insert pending bets: $e');
    }
  }

  /// Get user's pending bets
  static Future<List<Map<String, dynamic>>> getUserPendingBets() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('pending_bets')
          .select('''
            *,
            lottery_times(time_name, time_category),
            profile!pending_bets_user_id_fkey (
              full_name,
              phone
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch pending bets: $e');
    }
  }

  /// Move pending bets to bets table (when user clicks "បង់ប្រាក់")
  static Future<List<Map<String, dynamic>>> movePendingBetsToBets(
    List<int> pendingBetIds,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get pending bets data
      final pendingBets = await _supabase
          .from('pending_bets')
          .select('*')
          .inFilter('id', pendingBetIds)
          .eq('user_id', user.id);

      if (pendingBets.isEmpty) {
        throw Exception('No pending bets found');
      }

      // Prepare data for bets table (remove fields that don't exist in bets table)
      final betsData = pendingBets.map((bet) {
        final betMap = Map<String, dynamic>.from(bet);
        // Remove fields that don't exist in bets table
        betMap.remove('id');
        betMap.remove('created_at');
        betMap.remove('updated_at');
        betMap.remove('is_processed');
        betMap.remove('win_cause');
        betMap.remove('processed_at');
        return betMap;
      }).toList();

      // Insert into bets table
      final insertedBets = await _supabase
          .from('bets')
          .insert(betsData)
          .select();

      // Delete from pending_bets table
      await _supabase
          .from('pending_bets')
          .delete()
          .inFilter('id', pendingBetIds)
          .eq('user_id', user.id);

      return List<Map<String, dynamic>>.from(insertedBets);
    } catch (e) {
      throw Exception('Failed to move pending bets to bets: $e');
    }
  }

  /// Clear all pending bets for current user
  static Future<void> clearAllPendingBets() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('pending_bets').delete().eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to clear pending bets: $e');
    }
  }

  // ========== REGULAR BETS METHODS ==========

  /// Insert a new bet into the database
  static Future<Map<String, dynamic>> insertBet({
    required String customerName,
    required int lotteryTimeId,
    required String lotteryTime,
    required String betPattern,
    required List<String> betNumbers,
    required int amountPerNumber,
    required int totalAmount,
    required int multiplier,
    required String billType,
    required List<String> selectedConditions,
  }) async {
    try {
      // Get current user ID
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

      // Insert bet with conditions as JSON array
      final betResponse = await _supabase
          .from('bets')
          .insert({
            'customer_name': customerName,
            'lottery_time_id': lotteryTimeId,
            'lottery_time': lotteryTime,
            'bet_pattern': betPattern,
            'bet_numbers': betNumbers,
            'amount_per_number': amountPerNumber,
            'total_amount': totalAmount,
            'multiplier': multiplier,
            'bill_type': billType,
            'selected_conditions': selectedConditions, // Store as JSON array
            'bet_date': DateTime.now().toIso8601String().split(
              'T',
            )[0], // Current date
            'user_id': user.id,
            'admin_id': adminId, // Auto-populate admin_id
          })
          .select()
          .single();

      return betResponse;
    } catch (e) {
      throw Exception('Failed to insert bet: $e');
    }
  }

  /// Insert multiple bets (for batch operations)
  static Future<List<Map<String, dynamic>>> insertBets(
    List<Map<String, dynamic>> betsData,
  ) async {
    try {
      // Get current user ID
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

      // Prepare bets data with conditions stored as JSON array
      List<Map<String, dynamic>> cleanBetsData = [];

      for (var bet in betsData) {
        // Extract selectedConditions and store as JSON array
        List<String> selectedConditions = List<String>.from(
          bet['selectedConditions'] ?? [],
        );

        bet['selected_conditions'] = selectedConditions; // Store as JSON array
        bet.remove('selectedConditions'); // Remove old key
        bet['bet_date'] = DateTime.now().toIso8601String().split(
          'T',
        )[0]; // Current date
        bet['user_id'] = user.id;
        bet['admin_id'] = adminId; // Auto-populate admin_id
        cleanBetsData.add(bet);
      }

      // Insert bets with conditions as JSON array
      final betsResponse = await _supabase
          .from('bets')
          .insert(cleanBetsData)
          .select();

      return List<Map<String, dynamic>>.from(betsResponse);
    } catch (e) {
      throw Exception('Failed to insert bets: $e');
    }
  }

  /// Get bets for current user
  static Future<List<Map<String, dynamic>>> getUserBets({
    int? limit,
    int? offset,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabase
          .from('bets')
          .select('''
            *,
            lottery_times(time_name, time_category)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user bets: $e');
    }
  }
}
