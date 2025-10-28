import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/បញ្ជី_api.dart';

class ListService extends GetxController {
  // Observable variables
  final RxList<Map<String, dynamic>> _reportData = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> _summaryData = <String, dynamic>{}.obs;
  final RxBool _isLoading = false.obs;
  final Rx<DateTime> _selectedDate = DateTime.now().obs;
  final RxString _selectedLotteryTime = ''.obs;
  final RxMap<String, List<String>> _lotteryTimesGrouped =
      <String, List<String>>{}.obs;

  // Getters
  List<Map<String, dynamic>> get reportData => _reportData;
  Map<String, dynamic> get summaryData => _summaryData;
  bool get isLoading => _isLoading.value;
  DateTime get selectedDate => _selectedDate.value;
  String get selectedLotteryTime => _selectedLotteryTime.value;
  Map<String, List<String>> get lotteryTimesGrouped => _lotteryTimesGrouped;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  /// Initialize data
  void _initializeData() async {
    await fetchLotteryTimes();
    await fetchReportData();
  }

  /// Get current user ID
  String? get _currentUserId {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// Fetch lottery times grouped by category
  Future<void> fetchLotteryTimes() async {
    try {
      final groupedTimes = await ListApi.fetchLotteryTimesGrouped();
      _lotteryTimesGrouped.value = groupedTimes;

      // Set default lottery time if none selected
      if (_selectedLotteryTime.value.isEmpty) {
        // Try to set default to first available time from any category
        for (var category in groupedTimes.values) {
          if (category.isNotEmpty) {
            _selectedLotteryTime.value = category.first;
            break;
          }
        }
      }
    } catch (e) {
      print('Error fetching lottery times: $e');
      Get.snackbar('Error', 'Failed to fetch lottery times: $e');
    }
  }

  /// Fetch report data with date and agent filtering
  Future<void> fetchReportData() async {
    try {
      _isLoading.value = true;

      // Get current user ID
      final currentUserId = _currentUserId;
      if (currentUserId == null) {
        print('No current user found');
        _reportData.value = [];
        _summaryData.value = {};
        return;
      }

      // Fetch report data for current user only
      final reportDataMap = await ListApi.fetchReportData(
        selectedDate: _selectedDate.value,
        agentId: currentUserId,
        lotteryTime: _selectedLotteryTime.value.isNotEmpty
            ? _selectedLotteryTime.value
            : null,
      );

      // Process and aggregate data
      final processedData = _processReportData(
        reportDataMap['all_bets'] ?? [],
        reportDataMap['winning_results'] ?? [],
      );
      _reportData.value = processedData;

      // Calculate summary data from processed data
      _summaryData.value = _calculateSummaryData(processedData);
    } catch (e) {
      print('Error fetching report data: $e');
      Get.snackbar('Error', 'Failed to fetch report data: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Process raw report data into aggregated summaries
  /// Groups by agent and calculates totals for 2-digit and 3-digit bets
  /// Uses bet_results table data directly (like the React admin code)
  List<Map<String, dynamic>> _processReportData(
    List<Map<String, dynamic>> allBets,
    List<Map<String, dynamic>> winningResults,
  ) {
    Map<String, Map<String, dynamic>> agentData = {};
    String agentName = _getCurrentUserName();

    // Process WINNING RESULTS to get both bet amounts and payout amounts
    // This matches the React admin logic which uses bet_results table directly
    // Deduplicate by bet_id + number_type + channel_code to avoid counting same bet multiple times
    Set<String> processedResults = {};

    for (var result in winningResults) {
      // Create unique key for this result
      String resultKey =
          '${result['bet_id']}_${result['number_type']}_${result['channel_code']}';

      // Skip if already processed
      if (processedResults.contains(resultKey)) {
        print('Skipping duplicate result: $resultKey');
        continue;
      }

      processedResults.add(resultKey);
      try {
        Map<String, dynamic> betInfo = result['bets'] ?? {};
        String agentId = betInfo['user_id'] ?? '';
        String numberType = result['number_type'] ?? '';
        int betAmount = ((result['total_bet_amount'] ?? 0) as num).toInt();
        int payoutAmount = ((result['win_amount'] ?? 0) as num).toInt();
        String billType = betInfo['bill_type'] ?? 'ល.រ';

        // Initialize agent data if not exists
        if (!agentData.containsKey(agentId)) {
          agentData[agentId] = {
            'agent_id': agentId,
            'agent_name': agentName,
            'total_2digit_bets': 0,
            'total_3digit_bets': 0,
            'total_bet_amount': 0,
            'total_2digit_payouts': 0,
            'total_3digit_payouts': 0,
            'total_payout': 0,
            'agent_recorded_payout': 0,
            'customer_self_bet_payout': 0,
            'win_loss': 0,
            'bet_count': 0,
            'win_count': 0,
            'bets': <Map<String, dynamic>>[],
          };
        }

        // Categorize by number_type (2digit vs 3digit)
        bool is2Digit = numberType.toLowerCase() == '2digit';
        bool is3Digit = numberType.toLowerCase() == '3digit';

        // Update totals
        agentData[agentId]!['total_bet_amount'] += betAmount;
        agentData[agentId]!['total_payout'] += payoutAmount;
        agentData[agentId]!['bet_count'] += 1;
        agentData[agentId]!['win_count'] += 1;

        if (is2Digit) {
          agentData[agentId]!['total_2digit_bets'] += betAmount;
          agentData[agentId]!['total_2digit_payouts'] += payoutAmount;
        } else if (is3Digit) {
          agentData[agentId]!['total_3digit_bets'] += betAmount;
          agentData[agentId]!['total_3digit_payouts'] += payoutAmount;
        }

        // Determine payout type
        if (billType == 'ល.រ') {
          agentData[agentId]!['agent_recorded_payout'] += payoutAmount;
        } else {
          agentData[agentId]!['customer_self_bet_payout'] += payoutAmount;
        }

        // Add individual bet record
        agentData[agentId]!['bets'].add({
          'customer_name': betInfo['customer_name'] ?? '',
          'bet_pattern': betInfo['bet_pattern'] ?? '',
          'total_amount': betAmount,
          'win_amount': payoutAmount,
          'lottery_time': betInfo['lottery_time'] ?? '',
          'bill_type': billType,
          'number_type': numberType,
          'created_at': betInfo['created_at'],
        });
      } catch (e) {
        print('Error processing winning result: $e');
        continue;
      }
    }

    // Calculate win/loss for each agent
    for (var agentId in agentData.keys) {
      var agent = agentData[agentId]!;
      agent['win_loss'] = agent['total_bet_amount'] - agent['total_payout'];
    }

    // Convert to list and sort by agent name
    List<Map<String, dynamic>> result = agentData.values.toList();
    result.sort(
      (a, b) =>
          (a['agent_name'] as String).compareTo(b['agent_name'] as String),
    );

    return result;
  }

  /// Calculate summary data from processed report data
  Map<String, dynamic> _calculateSummaryData(
    List<Map<String, dynamic>> processedData,
  ) {
    int total2DigitBets = 0;
    int total3DigitBets = 0;
    int totalBetAmount = 0;
    int total2DigitPayouts = 0;
    int total3DigitPayouts = 0;
    int totalPayout = 0;
    int totalWinLoss = 0;
    int totalBetCount = 0;
    int totalWinCount = 0;

    for (var agent in processedData) {
      total2DigitBets += (agent['total_2digit_bets'] ?? 0) as int;
      total3DigitBets += (agent['total_3digit_bets'] ?? 0) as int;
      totalBetAmount += (agent['total_bet_amount'] ?? 0) as int;
      total2DigitPayouts += (agent['total_2digit_payouts'] ?? 0) as int;
      total3DigitPayouts += (agent['total_3digit_payouts'] ?? 0) as int;
      totalPayout += (agent['total_payout'] ?? 0) as int;
      totalWinLoss += (agent['win_loss'] ?? 0) as int;
      totalBetCount += (agent['bet_count'] ?? 0) as int;
      totalWinCount += (agent['win_count'] ?? 0) as int;
    }

    return {
      'total_2digit_bets': total2DigitBets,
      'total_3digit_bets': total3DigitBets,
      'total_bet_amount': totalBetAmount,
      'total_2digit_payouts': total2DigitPayouts,
      'total_3digit_payouts': total3DigitPayouts,
      'total_payout': totalPayout,
      'total_win_loss': totalWinLoss,
      'total_bet_count': totalBetCount,
      'total_win_count': totalWinCount,
      'agent_count': processedData.length,
    };
  }

  /// Update selected date and refresh data
  void updateSelectedDate(DateTime newDate) {
    _selectedDate.value = newDate;
    fetchReportData();
  }

  /// Update selected lottery time and refresh data
  void updateSelectedLotteryTime(String lotteryTime) {
    _selectedLotteryTime.value = lotteryTime;
    fetchReportData();
  }

  /// Get current user name
  String _getCurrentUserName() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user?.email?.split('@').first ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  /// Get formatted date string
  String getFormattedDate() {
    return '${_selectedDate.value.year}-${_selectedDate.value.month.toString().padLeft(2, '0')}-${_selectedDate.value.day.toString().padLeft(2, '0')}';
  }

  /// Get total summary across all agents
  Map<String, dynamic> getTotalSummary() {
    int total2DigitBets = 0;
    int total3DigitBets = 0;
    int totalBetAmount = 0;
    int total2DigitPayouts = 0;
    int total3DigitPayouts = 0;
    int totalPayout = 0;
    int totalWinLoss = 0;
    int totalBetCount = 0;
    int totalWinCount = 0;

    for (var agent in _reportData) {
      total2DigitBets += (agent['total_2digit_bets'] ?? 0) as int;
      total3DigitBets += (agent['total_3digit_bets'] ?? 0) as int;
      totalBetAmount += (agent['total_bet_amount'] ?? 0) as int;
      total2DigitPayouts += (agent['total_2digit_payouts'] ?? 0) as int;
      total3DigitPayouts += (agent['total_3digit_payouts'] ?? 0) as int;
      totalPayout += (agent['total_payout'] ?? 0) as int;
      totalWinLoss += (agent['win_loss'] ?? 0) as int;
      totalBetCount += (agent['bet_count'] ?? 0) as int;
      totalWinCount += (agent['win_count'] ?? 0) as int;
    }

    return {
      'total_2digit_bets': total2DigitBets,
      'total_3digit_bets': total3DigitBets,
      'total_bet_amount': totalBetAmount,
      'total_2digit_payouts': total2DigitPayouts,
      'total_3digit_payouts': total3DigitPayouts,
      'total_payout': totalPayout,
      'total_win_loss': totalWinLoss,
      'total_bet_count': totalBetCount,
      'total_win_count': totalWinCount,
      'agent_count': _reportData.length,
    };
  }

  /// Refresh all data
  Future<void> refreshData() async {
    await fetchReportData();
  }
}
