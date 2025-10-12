import '../api/ភ្នាល់_api.dart';

class LotteryTimesService {
  /// Get all active lottery times
  static Future<List<LotteryTime>> getAllLotteryTimes() async {
    try {
      final data = await LotteryTimesApi.getLotteryTimes();
      if (data.isEmpty) {
        return [];
      }
      return data.map((item) => LotteryTime.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching lottery times: $e');
      throw Exception('Failed to get lottery times: $e');
    }
  }

  /// Get lottery times by category
  static Future<List<LotteryTime>> getLotteryTimesByCategory(
    String category,
  ) async {
    try {
      final data = await LotteryTimesApi.getLotteryTimesByCategory(category);
      return data.map((item) => LotteryTime.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to get lottery times by category: $e');
    }
  }
}

class BetsService {
  // ========== PENDING BETS METHODS ==========

  /// Insert a pending bet (when user clicks "ចាក់ថ្មី")
  static Future<BetData> insertPendingBet({
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
      final response = await BetsApi.insertPendingBet(
        customerName: customerName,
        lotteryTimeId: lotteryTimeId,
        lotteryTime: lotteryTime,
        betPattern: betPattern,
        betNumbers: betNumbers,
        amountPerNumber: amountPerNumber,
        totalAmount: totalAmount,
        multiplier: multiplier,
        billType: billType,
        selectedConditions: selectedConditions,
      );

      return BetData.fromMap(response);
    } catch (e) {
      print('Error inserting pending bet: $e');
      throw Exception('Failed to insert pending bet: $e');
    }
  }

  /// Insert multiple pending bets (batch operation)
  static Future<List<BetData>> insertPendingBets(List<BetData> bets) async {
    try {
      final betsData = bets.map((bet) => bet.toMap()).toList();
      final response = await BetsApi.insertPendingBets(betsData);

      return response.map((item) => BetData.fromMap(item)).toList();
    } catch (e) {
      print('Error inserting pending bets: $e');
      throw Exception('Failed to insert pending bets: $e');
    }
  }

  /// Get user's pending bets
  static Future<List<BetData>> getUserPendingBets() async {
    try {
      final data = await BetsApi.getUserPendingBets();
      return data.map((item) => BetData.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching pending bets: $e');
      throw Exception('Failed to get pending bets: $e');
    }
  }

  /// Move pending bets to bets table (when user clicks "បង់ប្រាក់")
  static Future<List<BetData>> movePendingBetsToBets(
    List<int> pendingBetIds,
  ) async {
    try {
      final response = await BetsApi.movePendingBetsToBets(pendingBetIds);
      return response.map((item) => BetData.fromMap(item)).toList();
    } catch (e) {
      print('Error moving pending bets to bets: $e');
      throw Exception('Failed to move pending bets to bets: $e');
    }
  }

  /// Clear all pending bets for current user
  static Future<void> clearAllPendingBets() async {
    try {
      await BetsApi.clearAllPendingBets();
    } catch (e) {
      print('Error clearing pending bets: $e');
      throw Exception('Failed to clear pending bets: $e');
    }
  }

  // ========== REGULAR BETS METHODS ==========

  /// Insert a single bet
  static Future<BetData> insertBet({
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
      final response = await BetsApi.insertBet(
        customerName: customerName,
        lotteryTimeId: lotteryTimeId,
        lotteryTime: lotteryTime,
        betPattern: betPattern,
        betNumbers: betNumbers,
        amountPerNumber: amountPerNumber,
        totalAmount: totalAmount,
        multiplier: multiplier,
        billType: billType,
        selectedConditions: selectedConditions,
      );

      return BetData.fromMap(response);
    } catch (e) {
      print('Error inserting bet: $e');
      throw Exception('Failed to insert bet: $e');
    }
  }

  /// Insert multiple bets (batch operation)
  static Future<List<BetData>> insertBets(List<BetData> bets) async {
    try {
      final betsData = bets.map((bet) => bet.toMap()).toList();
      final response = await BetsApi.insertBets(betsData);

      return response.map((item) => BetData.fromMap(item)).toList();
    } catch (e) {
      print('Error inserting bets: $e');
      throw Exception('Failed to insert bets: $e');
    }
  }

  /// Get user's bets
  static Future<List<BetData>> getUserBets({int? limit, int? offset}) async {
    try {
      final data = await BetsApi.getUserBets(limit: limit, offset: offset);
      return data.map((item) => BetData.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching user bets: $e');
      throw Exception('Failed to get user bets: $e');
    }
  }
}

class LotteryTime {
  final int id;
  final String timeName;
  final String timeCategory;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LotteryTime({
    required this.id,
    required this.timeName,
    required this.timeCategory,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LotteryTime.fromMap(Map<String, dynamic> map) {
    return LotteryTime(
      id: map['id'] ?? 0,
      timeName: map['time_name'] ?? '',
      timeCategory: map['time_category'] ?? '',
      sortOrder: map['sort_order'] ?? 0,
      isActive: map['is_active'] ?? false,
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
      'id': id,
      'time_name': timeName,
      'time_category': timeCategory,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'LotteryTime(id: $id, timeName: $timeName, timeCategory: $timeCategory, sortOrder: $sortOrder, isActive: $isActive)';
  }
}

class BetData {
  final int? id; // Database ID (null for new bets)
  final String customerName;
  final int? lotteryTimeId; // Foreign key to lottery_times table
  final String lotteryTime;
  final String betPattern; // Store original pattern like "10-90"
  final List<String> betNumbers; // Keep for calculation
  final int amountPerNumber;
  final int totalAmount;
  final List<String> selectedConditions;
  final int multiplier;
  final String billType;
  final DateTime createdAt;
  final String? userId; // User ID who created the bet
  final String? userName; // User name who created the bet

  BetData({
    this.id,
    required this.customerName,
    this.lotteryTimeId,
    required this.lotteryTime,
    required this.betPattern,
    required this.betNumbers,
    required this.amountPerNumber,
    required this.totalAmount,
    required this.selectedConditions,
    required this.multiplier,
    this.billType = 'ល.រ',
    required this.createdAt,
    this.userId,
    this.userName,
  });

  static String _extractUserName(Map<String, dynamic> map) {
    print('Extracting user name from map: ${map.keys}');

    // Try to get user name from joined profile table
    if (map['profile'] != null) {
      final profile = map['profile'] as Map<String, dynamic>;
      print('Profile data: $profile');
      if (profile['full_name'] != null &&
          profile['full_name'].toString().isNotEmpty) {
        print('Using full_name: ${profile['full_name']}');
        return profile['full_name'];
      }
      if (profile['phone'] != null && profile['phone'].toString().isNotEmpty) {
        print('Using phone: ${profile['phone']}');
        return profile['phone'];
      }
    }

    // Fallback to direct fields
    if (map['user_name'] != null && map['user_name'].toString().isNotEmpty) {
      print('Using user_name: ${map['user_name']}');
      return map['user_name'];
    }
    if (map['user_email'] != null && map['user_email'].toString().isNotEmpty) {
      print('Using user_email: ${map['user_email']}');
      return map['user_email'];
    }

    print('Using default User');
    return 'User';
  }

  factory BetData.fromMap(Map<String, dynamic> map) {
    // Handle bet_conditions array if present
    List<String> conditions = [];
    if (map['bet_conditions'] != null) {
      final conditionsList = map['bet_conditions'] as List;
      conditions = conditionsList
          .map((condition) => condition['condition_name'] as String)
          .toList();
    } else if (map['selected_conditions'] != null) {
      conditions = List<String>.from(map['selected_conditions']);
    }

    return BetData(
      id: map['id'],
      customerName: map['customer_name'] ?? '',
      lotteryTimeId: map['lottery_time_id'],
      lotteryTime: map['lottery_time'] ?? '',
      betPattern: map['bet_pattern'] ?? '',
      betNumbers: List<String>.from(map['bet_numbers'] ?? []),
      amountPerNumber: map['amount_per_number'] ?? 0,
      totalAmount: map['total_amount'] ?? 0,
      selectedConditions: conditions,
      multiplier: map['multiplier'] ?? 1,
      billType: map['bill_type'] ?? 'ល.រ',
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      userId: map['user_id'],
      userName: _extractUserName(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_name': customerName,
      if (lotteryTimeId != null) 'lottery_time_id': lotteryTimeId,
      'lottery_time': lotteryTime,
      'bet_pattern': betPattern,
      'bet_numbers': betNumbers,
      'amount_per_number': amountPerNumber,
      'total_amount': totalAmount,
      'multiplier': multiplier,
      'bill_type': billType,
      'selectedConditions': selectedConditions, // Add this for batch operations
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BetData(id: $id, customerName: $customerName, lotteryTime: $lotteryTime, betPattern: $betPattern, totalAmount: $totalAmount)';
  }
}
