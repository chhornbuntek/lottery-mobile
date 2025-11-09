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

  /// Generate unique invoice number
  /// Format: Sequential number per day per user (បុង 1, បុង 2, បុង 3, ...)
  static Future<String> _generateInvoiceNumber() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Get the highest invoice number for today FROM CURRENT USER ONLY
      final pendingBetsQuery = await _supabase
          .from('pending_bets')
          .select('invoice_number')
          .eq('user_id', user.id)
          .eq('bet_date', dateStr)
          .not('invoice_number', 'is', null);

      final betsQuery = await _supabase
          .from('bets')
          .select('invoice_number')
          .eq('user_id', user.id)
          .eq('bet_date', dateStr)
          .not('invoice_number', 'is', null);

      final allInvoiceNumbers = <String>[];

      // Extract numbers from pending_bets (current user only)
      for (var bet in pendingBetsQuery) {
        final invoiceNum = bet['invoice_number'] as String?;
        if (invoiceNum != null && invoiceNum.isNotEmpty) {
          allInvoiceNumbers.add(invoiceNum);
        }
      }

      // Extract numbers from bets (current user only)
      for (var bet in betsQuery) {
        final invoiceNum = bet['invoice_number'] as String?;
        if (invoiceNum != null && invoiceNum.isNotEmpty) {
          allInvoiceNumbers.add(invoiceNum);
        }
      }

      // Find the highest number
      int maxNumber = 0;
      for (var invoiceNum in allInvoiceNumbers) {
        // Extract number from "បុង 1", "បុង 2", etc.
        final match = RegExp(r'បុង\s*(\d+)').firstMatch(invoiceNum);
        if (match != null) {
          final num = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (num > maxNumber) {
            maxNumber = num;
          }
        }
      }

      // Return next sequential number (unique per user per day)
      return 'បុង ${maxNumber + 1}';
    } catch (e) {
      // Fallback: use timestamp-based number if query fails
      final now = DateTime.now();
      return 'បុង ${now.millisecondsSinceEpoch % 10000}';
    }
  }

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

      // Generate invoice number
      final invoiceNumber = await _generateInvoiceNumber();

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
            'invoice_number': invoiceNumber, // Auto-generate invoice number
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

      // Get starting invoice number for batch
      String startInvoiceNumber = await _generateInvoiceNumber();
      int startNumber = 0;
      final match = RegExp(r'បុង\s*(\d+)').firstMatch(startInvoiceNumber);
      if (match != null) {
        startNumber = int.tryParse(match.group(1) ?? '0') ?? 0;
      }

      // Add user_id, admin_id, and invoice_number to all pending bets
      int index = 0;
      for (var bet in pendingBetsData) {
        bet['user_id'] = user.id;
        bet['admin_id'] = adminId; // Auto-populate admin_id
        // Generate invoice_number if not already provided
        if (bet['invoice_number'] == null ||
            (bet['invoice_number'] as String).isEmpty) {
          bet['invoice_number'] = 'បុង ${startNumber + index}';
          index++;
        }
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
        // Keep invoice_number - it should be preserved from pending_bets
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

  /// Move bets back to pending_bets table (when user cancels payment)
  static Future<List<Map<String, dynamic>>> moveBetsToPendingBets(
    List<int> betIds,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get bets data
      final bets = await _supabase
          .from('bets')
          .select('*')
          .inFilter('id', betIds)
          .eq('user_id', user.id);

      if (bets.isEmpty) {
        throw Exception('No bets found');
      }

      // Prepare data for pending_bets table (remove fields that don't exist in pending_bets table)
      final pendingBetsData = bets.map((bet) {
        final betMap = Map<String, dynamic>.from(bet);
        // Remove fields that don't exist in pending_bets table
        betMap.remove('id');
        betMap.remove('created_at');
        betMap.remove('updated_at');
        // Add fields that exist in pending_bets but not in bets
        betMap['is_processed'] = false;
        // Keep invoice_number - it should be preserved from bets
        return betMap;
      }).toList();

      // Insert into pending_bets table
      final insertedPendingBets = await _supabase
          .from('pending_bets')
          .insert(pendingBetsData)
          .select();

      // Delete from bets table
      await _supabase
          .from('bets')
          .delete()
          .inFilter('id', betIds)
          .eq('user_id', user.id);

      return List<Map<String, dynamic>>.from(insertedPendingBets);
    } catch (e) {
      throw Exception('Failed to move bets to pending bets: $e');
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

  /// Delete a single pending bet by ID
  static Future<void> deletePendingBet(int betId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('pending_bets')
          .delete()
          .eq('id', betId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete pending bet: $e');
    }
  }

  /// Delete a single bet from bets table by ID
  static Future<void> deleteBet(int betId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('bets')
          .delete()
          .eq('id', betId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete bet: $e');
    }
  }

  /// Update existing pending bet by appending new bet numbers
  /// Can also merge conditions if new conditions are provided
  static Future<Map<String, dynamic>> updatePendingBet({
    required int betId,
    required List<String> newBetNumbers,
    required String newBetPattern,
    required int newAmountPerNumber,
    List<String>? newConditions, // Optional: new conditions to merge
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current pending bet
      final currentBet = await _supabase
          .from('pending_bets')
          .select('*')
          .eq('id', betId)
          .eq('user_id', user.id)
          .single();

      // Append new bet numbers to existing ones
      final existingNumbers = List<String>.from(
        currentBet['bet_numbers'] ?? [],
      );
      final updatedNumbers = [...existingNumbers, ...newBetNumbers];

      // Append new pattern to existing pattern
      final existingPattern = currentBet['bet_pattern'] ?? '';
      final updatedPattern = existingPattern.isEmpty
          ? newBetPattern
          : '$existingPattern, $newBetPattern';

      // Calculate new total amount
      final oldTotalAmount = currentBet['total_amount'] as int;
      final newBetAmount = newBetNumbers.length * newAmountPerNumber;
      final newTotalAmount = oldTotalAmount + newBetAmount;

      // Build update data
      Map<String, dynamic> updateData = {
        'bet_numbers': updatedNumbers,
        'bet_pattern': updatedPattern,
        'total_amount': newTotalAmount,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Merge conditions if new conditions are provided
      if (newConditions != null) {
        final existingConditions = List<String>.from(
          currentBet['selected_conditions'] ?? [],
        );
        // Merge: combine existing and new conditions, remove duplicates
        final mergedConditions = {
          ...existingConditions,
          ...newConditions,
        }.toList();
        updateData['selected_conditions'] = mergedConditions;
      }

      // Update the pending bet
      final updatedBet = await _supabase
          .from('pending_bets')
          .update(updateData)
          .eq('id', betId)
          .eq('user_id', user.id)
          .select()
          .single();

      return updatedBet;
    } catch (e) {
      throw Exception('Failed to update pending bet: $e');
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

      // Generate invoice number
      final invoiceNumber = await _generateInvoiceNumber();

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
            'invoice_number': invoiceNumber, // Auto-generate invoice number
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
        // Generate invoice_number if not already provided
        if (bet['invoice_number'] == null ||
            (bet['invoice_number'] as String).isEmpty) {
          bet['invoice_number'] = await _generateInvoiceNumber();
        }
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

  /// Get all bets (pending and paid) by date for current user
  /// Returns list with 'source' field: 'pending_bets' or 'bets'
  static Future<List<Map<String, dynamic>>> getAllBetsByDate({
    required DateTime date,
    String? billType,
    String? lotteryTime,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Fetch pending bets
      var pendingQuery = _supabase
          .from('pending_bets')
          .select('*')
          .eq('user_id', user.id)
          .eq('bet_date', formattedDate);

      if (billType != null && billType.isNotEmpty) {
        pendingQuery = pendingQuery.eq('bill_type', billType);
      }

      if (lotteryTime != null && lotteryTime.isNotEmpty) {
        pendingQuery = pendingQuery.eq('lottery_time', lotteryTime);
      }

      final pendingBets = await pendingQuery.order(
        'created_at',
        ascending: false,
      );

      // Fetch paid bets
      var betsQuery = _supabase
          .from('bets')
          .select('*')
          .eq('user_id', user.id)
          .eq('bet_date', formattedDate);

      if (billType != null && billType.isNotEmpty) {
        betsQuery = betsQuery.eq('bill_type', billType);
      }

      if (lotteryTime != null && lotteryTime.isNotEmpty) {
        betsQuery = betsQuery.eq('lottery_time', lotteryTime);
      }

      final bets = await betsQuery.order('created_at', ascending: false);

      // Combine and mark source
      List<Map<String, dynamic>> allBets = [];

      // Add pending bets with source marker
      for (var bet in pendingBets) {
        final betMap = Map<String, dynamic>.from(bet);
        betMap['source'] = 'pending_bets';
        allBets.add(betMap);
      }

      // Add paid bets with source marker
      for (var bet in bets) {
        final betMap = Map<String, dynamic>.from(bet);
        betMap['source'] = 'bets';
        allBets.add(betMap);
      }

      // Sort by created_at descending
      allBets.sort((a, b) {
        final aTime = DateTime.parse(
          a['created_at'] ?? DateTime.now().toIso8601String(),
        );
        final bTime = DateTime.parse(
          b['created_at'] ?? DateTime.now().toIso8601String(),
        );
        return bTime.compareTo(aTime);
      });

      return allBets;
    } catch (e) {
      throw Exception('Failed to fetch all bets by date: $e');
    }
  }

  /// Get bet groups summary by date for current user
  /// Returns aggregated groups with total_amount pre-calculated
  static Future<List<Map<String, dynamic>>> getBetGroupsSummary({
    required DateTime date,
    String? billType,
    String? lotteryTime,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      var query = _supabase
          .from('bet_groups_summary')
          .select('*')
          .eq('user_id', user.id)
          .eq('bet_date', formattedDate);

      if (billType != null && billType.isNotEmpty) {
        query = query.eq('bill_type', billType);
      }

      if (lotteryTime != null && lotteryTime.isNotEmpty) {
        query = query.eq('lottery_time', lotteryTime);
      }

      final groups = await query.order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(groups);
    } catch (e) {
      throw Exception('Failed to fetch bet groups summary: $e');
    }
  }

  /// Get bets by IDs from bet_groups_summary
  /// Returns bets from both pending_bets and bets tables based on paid_count
  static Future<List<Map<String, dynamic>>> getBetsByGroupSummary({
    required String customerName,
    required String lotteryTime,
    required DateTime date,
    String? billType,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Get group summary
      var query = _supabase
          .from('bet_groups_summary')
          .select('*')
          .eq('user_id', user.id)
          .eq('customer_name', customerName)
          .eq('lottery_time', lotteryTime)
          .eq('bet_date', formattedDate);

      if (billType != null && billType.isNotEmpty) {
        query = query.eq('bill_type', billType);
      }

      final groups = await query;

      if (groups.isEmpty) {
        return [];
      }

      final group = groups.first;
      final betIds = (group['bet_ids'] as List<dynamic>?) ?? [];
      final paidCount = (group['paid_count'] as int?) ?? 0;
      final pendingCount = (group['pending_count'] as int?) ?? 0;

      if (betIds.isEmpty) {
        return [];
      }

      // Convert bet_ids to integers
      List<int> betIdInts = betIds
          .map((id) => int.tryParse(id.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();

      if (betIdInts.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> allBets = [];

      // Get pending bets (first pending_count IDs)
      if (pendingCount > 0 && betIdInts.length >= pendingCount) {
        List<int> pendingBetIds = betIdInts.sublist(0, pendingCount);

        if (pendingBetIds.isNotEmpty) {
          final pendingBets = await _supabase
              .from('pending_bets')
              .select('*')
              .inFilter('id', pendingBetIds)
              .eq('user_id', user.id);

          for (var bet in pendingBets) {
            bet['source'] = 'pending_bets';
            allBets.add(bet);
          }
        }
      }

      // Get paid bets (last paid_count IDs)
      if (paidCount > 0 && betIdInts.length >= pendingCount + paidCount) {
        List<int> paidBetIds = betIdInts.sublist(
          pendingCount,
          pendingCount + paidCount,
        );

        if (paidBetIds.isNotEmpty) {
          final paidBets = await _supabase
              .from('bets')
              .select('*')
              .inFilter('id', paidBetIds)
              .eq('user_id', user.id);

          for (var bet in paidBets) {
            bet['source'] = 'bets';
            allBets.add(bet);
          }
        }
      }

      return allBets;
    } catch (e) {
      throw Exception('Failed to fetch bets by group summary: $e');
    }
  }

  /// Update existing bet in bets table
  static Future<Map<String, dynamic>> updateBet({
    required int betId,
    String? customerName,
    int? lotteryTimeId,
    String? lotteryTime,
    String? betPattern,
    List<String>? betNumbers,
    int? amountPerNumber,
    int? totalAmount,
    int? multiplier,
    String? billType,
    List<String>? selectedConditions,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Build update data (only include non-null fields)
      Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (customerName != null) updateData['customer_name'] = customerName;
      if (lotteryTimeId != null) updateData['lottery_time_id'] = lotteryTimeId;
      if (lotteryTime != null) updateData['lottery_time'] = lotteryTime;
      if (betPattern != null) updateData['bet_pattern'] = betPattern;
      if (betNumbers != null) updateData['bet_numbers'] = betNumbers;
      if (amountPerNumber != null)
        updateData['amount_per_number'] = amountPerNumber;
      if (totalAmount != null) updateData['total_amount'] = totalAmount;
      if (multiplier != null) updateData['multiplier'] = multiplier;
      if (billType != null) updateData['bill_type'] = billType;
      if (selectedConditions != null)
        updateData['selected_conditions'] = selectedConditions;

      // Update the bet
      final updatedBet = await _supabase
          .from('bets')
          .update(updateData)
          .eq('id', betId)
          .eq('user_id', user.id)
          .select()
          .single();

      return updatedBet;
    } catch (e) {
      throw Exception('Failed to update bet: $e');
    }
  }

  /// Update existing pending bet (full update, not append)
  static Future<Map<String, dynamic>> updatePendingBetFull({
    required int betId,
    String? customerName,
    int? lotteryTimeId,
    String? lotteryTime,
    String? betPattern,
    List<String>? betNumbers,
    int? amountPerNumber,
    int? totalAmount,
    int? multiplier,
    String? billType,
    List<String>? selectedConditions,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Build update data (only include non-null fields)
      Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (customerName != null) updateData['customer_name'] = customerName;
      if (lotteryTimeId != null) updateData['lottery_time_id'] = lotteryTimeId;
      if (lotteryTime != null) updateData['lottery_time'] = lotteryTime;
      if (betPattern != null) updateData['bet_pattern'] = betPattern;
      if (betNumbers != null) updateData['bet_numbers'] = betNumbers;
      if (amountPerNumber != null)
        updateData['amount_per_number'] = amountPerNumber;
      if (totalAmount != null) updateData['total_amount'] = totalAmount;
      if (multiplier != null) updateData['multiplier'] = multiplier;
      if (billType != null) updateData['bill_type'] = billType;
      if (selectedConditions != null)
        updateData['selected_conditions'] = selectedConditions;

      // Update the pending bet
      final updatedBet = await _supabase
          .from('pending_bets')
          .update(updateData)
          .eq('id', betId)
          .eq('user_id', user.id)
          .select()
          .single();

      return updatedBet;
    } catch (e) {
      throw Exception('Failed to update pending bet: $e');
    }
  }

  /// Get bet by ID from either pending_bets or bets table
  static Future<Map<String, dynamic>> getBetById({
    required int betId,
    required String source, // 'pending_bets' or 'bets'
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final tableName = source == 'pending_bets' ? 'pending_bets' : 'bets';

      final bet = await _supabase
          .from(tableName)
          .select('*')
          .eq('id', betId)
          .eq('user_id', user.id)
          .single();

      final betMap = Map<String, dynamic>.from(bet);
      betMap['source'] = source;
      return betMap;
    } catch (e) {
      throw Exception('Failed to fetch bet: $e');
    }
  }

  /// Get money limit for a specific time and number type
  /// Returns the limit_per_number as int, or null if not found
  static Future<int?> getMoneyLimit({
    required String time,
    required String numberType, // '2 លេខ' or '3 លេខ'
  }) async {
    try {
      final response = await _supabase
          .from('money_limit')
          .select('limit_per_number')
          .eq('time', time)
          .eq('number_type', numberType)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final limitStr = response['limit_per_number'] as String? ?? '';
      return int.tryParse(limitStr);
    } catch (e) {
      print('Error fetching money limit: $e');
      return null; // Return null on error (fail open - allow betting)
    }
  }
}
