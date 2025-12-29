import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/ភ្នាល់_service.dart';
import '../api/ភ្នាល់_api.dart';
import '../service/ម៉ោងបិទ_service.dart';
import 'របៀបបញ្ចូល.dart';
import 'receipt_preview.dart';

// BetData class is now imported from service file

class BettingScreen extends StatefulWidget {
  const BettingScreen({super.key});

  @override
  State<BettingScreen> createState() => _BettingScreenState();
}

class _BettingScreenState extends State<BettingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _betNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final String _selectedBill = 'ល.រ';
  LotteryTime? _selectedLotteryTime;
  List<String> _expandedNumbers = [];
  List<BetData> _betList = [];
  int _totalAmount = 0;
  List<int> _pendingBetIds = [];
  final Map<String, bool> _checkboxes = {
    '4P': false,
    'F': false,
    'B': false,
    '7P': false,
    'I': false,
    'C': false,
    'Lo': false,
    'N': false,
    'D': false,
    'A': false,
  };
  int _focusedFieldIndex =
      0; // Track which field is focused: 0=name, 1=bet, 2=amount

  // Edit mode state
  bool _isEditMode = false;
  List<Map<String, dynamic>> _betsToEdit =
      []; // All bets to edit from selected groups
  Map<String, dynamic>?
  _betBeingEdited; // Currently selected bet for editing in form
  int? _editingBetId;
  int _currentEditIndex = 0; // Index of currently editing bet
  bool _isSaving = false;

  void _onKeypadPressed(String value) {
    setState(() {
      switch (_focusedFieldIndex) {
        case 0:
          _nameController.text += value;
          break;
        case 1:
          _betNumberController.text += value;
          // Always try to expand numbers, whether special pattern or regular numbers
          _expandedNumbers = _expandBetNumbers(_betNumberController.text);
          break;
        case 2:
          _amountController.text += value;
          break;
      }
    });
  }

  List<String> _expandBetNumbers(String input) {
    List<String> expandedNumbers = [];

    // Handle x (reverse) pattern: 10x = 10, 01 | 125x = all permutations | 122x = unique permutations
    if (input.contains('x')) {
      String baseNumber = input.replaceAll('x', '');
      if (baseNumber.length == 2) {
        // 2-digit: 10x = 10, 01
        expandedNumbers.add(baseNumber);
        expandedNumbers.add(baseNumber.split('').reversed.join(''));
      } else if (baseNumber.length == 3) {
        // 3-digit: Generate all permutations
        List<String> digits = baseNumber.split('');
        Set<String> permutations = <String>{};

        // Generate all possible permutations
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            for (int k = 0; k < 3; k++) {
              if (i != j && j != k && i != k) {
                permutations.add('${digits[i]}${digits[j]}${digits[k]}');
              }
            }
          }
        }

        // Add all unique permutations
        expandedNumbers.addAll(permutations.toList());
      }
      return expandedNumbers;
    }

    // Handle > (drag) pattern for 2-digit: 10> = 10, 11, 12, ..., 19 | 25> = 25, 35, 45, ..., 95
    // Handle > (drag) pattern for 3-digit: 157> = 157, 158, ..., 999
    if (input.contains('>')) {
      List<String> parts = input.split('>');
      if (parts.length == 2 && parts[1].isEmpty) {
        // Single number with > (drag pattern)
        String start = parts[0];

        if (start.length == 2) {
          int startNum = int.tryParse(start) ?? 0;
          int firstDigit = startNum ~/ 10;
          int lastDigit = startNum % 10;

          // Check if it's a tail drag pattern (like 25> = 25, 35, 45, ..., 95)
          // Tail drag: when the first digit is 2 or higher and last digit is 5 or higher
          // Regular drag: when first digit is 1 or when last digit is 0-4
          if (firstDigit >= 2 && lastDigit >= 5) {
            // Tail drag pattern: increment first digit by 10, keep last digit
            for (int i = firstDigit; i <= 9; i++) {
              expandedNumbers.add('${i}${lastDigit}');
            }
          } else {
            // Regular drag pattern: increment last digit from start to 9
            for (int i = lastDigit; i <= 9; i++) {
              expandedNumbers.add('${firstDigit}${i}');
            }
          }
        } else if (start.length == 3) {
          // 3-digit pattern: 157> = 157, 158, ..., 999
          int startNum = int.tryParse(start) ?? 0;
          for (int i = startNum; i <= 999; i++) {
            expandedNumbers.add(i.toString().padLeft(3, '0'));
          }
        }
      } else if (parts.length == 2 && parts[1].isNotEmpty) {
        // Range pattern: 157>162 = 157, 158, 159, 160, 161, 162
        String start = parts[0];
        String end = parts[1];

        if (start.length == 2 && end.length == 2) {
          int startNum = int.tryParse(start) ?? 0;
          int endNum = int.tryParse(end) ?? 0;
          for (int i = startNum; i <= endNum; i++) {
            expandedNumbers.add(i.toString().padLeft(2, '0'));
          }
        } else if (start.length == 3 && end.length == 3) {
          int startNum = int.tryParse(start) ?? 0;
          int endNum = int.tryParse(end) ?? 0;
          for (int i = startNum; i <= endNum; i++) {
            expandedNumbers.add(i.toString().padLeft(3, '0'));
          }
        }
      }
      return expandedNumbers;
    }

    // Handle -x (reverse drag) pattern: 10-19x = 10, 01, 11, 12, 21, ..., 19, 91
    if (input.contains('-') && input.contains('x')) {
      List<String> parts = input.split('-');
      if (parts.length == 2) {
        String start = parts[0];
        String endWithX = parts[1];
        String end = endWithX.replaceAll('x', '');

        if (start.length == 2 && end.length == 2) {
          // 2-digit reverse drag pattern: 10-19x = 10, 01, 11, 12, 21, ..., 19, 91
          int startNum = int.tryParse(start) ?? 0;
          int endNum = int.tryParse(end) ?? 0;

          for (int i = startNum; i <= endNum; i++) {
            String number = i.toString().padLeft(2, '0');
            expandedNumbers.add(number);
            // Add reverse if it's different
            String reversed = number.split('').reversed.join('');
            if (reversed != number) {
              expandedNumbers.add(reversed);
            }
          }
        }
      }
      return expandedNumbers;
    }

    // Handle - (sequential) pattern for 2-digit: 01-46 = 01, 02, 03, ..., 46
    // Handle - (drag straight) pattern for 3-digit with different rules
    if (input.contains('-')) {
      List<String> parts = input.split('-');
      if (parts.length == 2) {
        String start = parts[0];
        String end = parts[1];

        if (start.length == 2 && end.length == 2) {
          // 2-digit patterns
          // Pattern 1: 10-50 = 10, 20, 30, 40, 50 (first digit changes, last digit stays same)
          // Example: 56-96 = 56, 66, 76, 86, 96
          if (start[1] == end[1] && start[0] != end[0]) {
            int lastDigit = int.parse(start[1]);
            int startFirst = int.parse(start[0]);
            int endFirst = int.parse(end[0]);

            for (int i = startFirst; i <= endFirst; i++) {
              expandedNumbers.add('$i$lastDigit');
            }
          }
          // Pattern 2: 11-44 = 11, 22, 33, 44 (both digits change together - same digit pattern)
          // Check if both digits are the same in start and both change together
          else if (start[0] == start[1] &&
              end[0] == end[1] &&
              start[0] != end[0] &&
              start[1] != end[1]) {
            int startDigit = int.parse(start[0]);
            int endDigit = int.parse(end[0]);

            for (int i = startDigit; i <= endDigit; i++) {
              expandedNumbers.add('$i$i');
            }
          }
          // Pattern 3: 10-16 = 10, 11, 12, 13, 14, 15, 16 (last digit changes, first digit stays same)
          // Example: 56-59 = 56, 57, 58, 59
          else if (start[0] == end[0] && start[1] != end[1]) {
            int firstDigit = int.parse(start[0]);
            int startLast = int.parse(start[1]);
            int endLast = int.parse(end[1]);

            for (int i = startLast; i <= endLast; i++) {
              expandedNumbers.add('$firstDigit$i');
            }
          }
          // Pattern 4: Sequential range (01-46 = 01, 02, 03, ..., 46) - default fallback
          else {
            int startNum = int.tryParse(start) ?? 0;
            int endNum = int.tryParse(end) ?? 0;

            for (int i = startNum; i <= endNum; i++) {
              expandedNumbers.add(i.toString().padLeft(2, '0'));
            }
          }
        } else if (start.length == 3 && end.length == 3) {
          // 3-digit patterns
          int startNum = int.tryParse(start) ?? 0;
          int endNum = int.tryParse(end) ?? 0;

          // Pattern 1: 000-333 = 000, 111, 222, 333 (same digits)
          if (start[0] == start[1] &&
              start[1] == start[2] &&
              end[0] == end[1] &&
              end[1] == end[2]) {
            for (int i = startNum; i <= endNum; i += 111) {
              expandedNumbers.add(i.toString().padLeft(3, '0'));
            }
          }
          // Pattern 2: 123-153 = 123, 133, 143, 153 (middle digit changes)
          else if (start[0] == end[0] &&
              start[2] == end[2] &&
              start[1] != end[1]) {
            int firstDigit = int.parse(start[0]);
            int lastDigit = int.parse(start[2]);
            int startMiddle = int.parse(start[1]);
            int endMiddle = int.parse(end[1]);

            for (int i = startMiddle; i <= endMiddle; i++) {
              expandedNumbers.add('$firstDigit$i$lastDigit');
            }
          }
          // Pattern 3: 120-620 = 120, 220, 320, 420, 520, 620 (first digit changes)
          else if (start[1] == end[1] &&
              start[2] == end[2] &&
              start[0] != end[0]) {
            int middleDigit = int.parse(start[1]);
            int lastDigit = int.parse(start[2]);
            int startFirst = int.parse(start[0]);
            int endFirst = int.parse(end[0]);

            for (int i = startFirst; i <= endFirst; i++) {
              expandedNumbers.add('$i$middleDigit$lastDigit');
            }
          }
          // Pattern 4: 122-144 = 122, 133, 144 (diagonal pattern)
          else if (start[0] == end[0] &&
              start[1] == end[1] &&
              start[2] != end[2]) {
            int firstDigit = int.parse(start[0]);
            int middleDigit = int.parse(start[1]);
            int startLast = int.parse(start[2]);
            int endLast = int.parse(end[2]);

            for (int i = startLast; i <= endLast; i++) {
              expandedNumbers.add('$firstDigit$middleDigit$i');
            }
          }
          // Pattern 5: 221-661 = 221, 331, 441, 551, 661 (head same pattern)
          else if (start[0] == end[0] &&
              start[1] != end[1] &&
              start[2] != end[2]) {
            int firstDigit = int.parse(start[0]);
            int startMiddle = int.parse(start[1]);
            int endMiddle = int.parse(end[1]);
            int startLast = int.parse(start[2]);
            int endLast = int.parse(end[2]);

            // Calculate the increment for middle and last digits
            int middleIncrement = endMiddle - startMiddle;
            int lastIncrement = endLast - startLast;

            // Generate numbers with same first digit, incrementing middle and last
            int steps = middleIncrement.abs();
            for (int i = 0; i <= steps; i++) {
              int middle = startMiddle + (middleIncrement * i ~/ steps);
              int last = startLast + (lastIncrement * i ~/ steps);
              expandedNumbers.add('$firstDigit$middle$last');
            }
          }
          // Pattern 6: 121-525 = 121, 222, 323, 424, 525 (diagonal pattern)
          else if (start[0] != end[0] &&
              start[1] != end[1] &&
              start[2] != end[2]) {
            int startFirst = int.parse(start[0]);
            int endFirst = int.parse(end[0]);
            int startMiddle = int.parse(start[1]);
            int endMiddle = int.parse(end[1]);
            int startLast = int.parse(start[2]);
            int endLast = int.parse(end[2]);

            int steps = (endFirst - startFirst).abs();
            for (int i = 0; i <= steps; i++) {
              int first = startFirst + (endFirst - startFirst) * i ~/ steps;
              int middle = startMiddle + (endMiddle - startMiddle) * i ~/ steps;
              int last = startLast + (endLast - startLast) * i ~/ steps;
              expandedNumbers.add('$first$middle$last');
            }
          }
        }
      }
      return expandedNumbers;
    }

    // If no special pattern, handle regular numbers
    if (input.isNotEmpty) {
      // If it's a single number or simple sequence, add it as is
      expandedNumbers.add(input);
    }
    return expandedNumbers;
  }

  void _onClearPressed() {
    setState(() {
      switch (_focusedFieldIndex) {
        case 0:
          _nameController.clear();
          break;
        case 1:
          _betNumberController.clear();
          _expandedNumbers.clear();
          break;
        case 2:
          _amountController.clear();
          break;
      }
    });
  }

  void _onBackspacePressed() {
    setState(() {
      switch (_focusedFieldIndex) {
        case 0:
          if (_nameController.text.isNotEmpty) {
            _nameController.text = _nameController.text.substring(
              0,
              _nameController.text.length - 1,
            );
          }
          break;
        case 1:
          if (_betNumberController.text.isNotEmpty) {
            _betNumberController.text = _betNumberController.text.substring(
              0,
              _betNumberController.text.length - 1,
            );
            // Always try to expand numbers, whether special pattern or regular numbers
            _expandedNumbers = _expandBetNumbers(_betNumberController.text);
          }
          break;
        case 2:
          if (_amountController.text.isNotEmpty) {
            _amountController.text = _amountController.text.substring(
              0,
              _amountController.text.length - 1,
            );
          }
          break;
      }
    });
  }

  void _switchFocus() {
    setState(() {
      _focusedFieldIndex = (_focusedFieldIndex + 1) % 3;
    });
  }

  void _handleCheckboxChange(String checkboxKey, bool value) {
    setState(() {
      if (checkboxKey == '4P' && value) {
        // 4P selected
        _checkboxes['4P'] = true;
        // For all times: auto select A, B, C, D (NOT Lo)
        _checkboxes['A'] = true;
        _checkboxes['B'] = true;
        _checkboxes['C'] = true;
        _checkboxes['D'] = true;
        // Lo should NOT be auto-selected - user must manually select it
      } else if (checkboxKey == '7P' && value) {
        // 7P selected: auto select F, I, N, A, B, C, D
        _checkboxes['7P'] = true;
        _checkboxes['F'] = true;
        _checkboxes['I'] = true;
        _checkboxes['N'] = true;
        _checkboxes['A'] = true;
        _checkboxes['B'] = true;
        _checkboxes['C'] = true;
        _checkboxes['D'] = true;
      } else if (checkboxKey == '4P' && !value) {
        // 4P deselected: uncheck A, B, C, D (but NOT Lo - user may have manually selected it)
        _checkboxes['4P'] = false;
        _checkboxes['A'] = false;
        _checkboxes['B'] = false;
        _checkboxes['C'] = false;
        _checkboxes['D'] = false;
        // Lo should NOT be unchecked when 4P is deselected
      } else if (checkboxKey == '7P' && !value) {
        // 7P deselected: uncheck F, I, N, A, B, C, D only if they were auto-selected
        _checkboxes['7P'] = false;
        _checkboxes['F'] = false;
        _checkboxes['I'] = false;
        _checkboxes['N'] = false;
        _checkboxes['A'] = false;
        _checkboxes['B'] = false;
        _checkboxes['C'] = false;
        _checkboxes['D'] = false;
      } else {
        // Regular checkbox change
        _checkboxes[checkboxKey] = value;
      }
    });
  }

  int _calculateTotalAmount() {
    int total = 0;
    for (var bet in _betList) {
      total += bet.totalAmount;
    }
    return total;
  }

  /// Calculate total amount from bets being edited
  int _calculateEditModeTotalAmount() {
    int total = 0;
    for (var bet in _betsToEdit) {
      final totalAmount = bet['total_amount'] as int? ?? 0;
      total += totalAmount;
    }
    return total;
  }

  /// Check if any selected posts are currently closed
  Future<List<String>> _checkClosedPosts(
    String lotteryTimeName,
    List<String> selectedConditions,
  ) async {
    try {
      // Get all closing times
      List<ClosingTime> closingTimes =
          await ClosingTimeService.getAllClosingTimes();

      // Find closing time for the selected lottery time
      ClosingTime? closingTime = closingTimes.firstWhere(
        (ct) => ct.timeName == lotteryTimeName,
        orElse: () => ClosingTime(
          id: 0,
          timeName: '',
          startTime: '',
          endTime: '',
          vipEnabled: false,
          posts: [],
        ),
      );

      // If no closing time found for this lottery time, allow betting
      if (closingTime.id == 0 || closingTime.posts.isEmpty) {
        return [];
      }

      // Get current time and day
      DateTime now = DateTime.now();
      int dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
      TimeOfDay currentTime = TimeOfDay.fromDateTime(now);

      // Get day name
      String dayName = '';
      switch (dayOfWeek) {
        case 1:
          dayName = 'monday';
          break;
        case 2:
          dayName = 'tuesday';
          break;
        case 3:
          dayName = 'wednesday';
          break;
        case 4:
          dayName = 'thursday';
          break;
        case 5:
          dayName = 'friday';
          break;
        case 6:
          dayName = 'saturday';
          break;
        case 7:
          dayName = 'sunday';
          break;
      }

      // Convert current time to minutes for comparison
      int currentMinutes = currentTime.hour * 60 + currentTime.minute;

      // Parse end_time from closing_time table (general end time for lottery time)
      List<String> endTimeParts = closingTime.endTime.split(':');
      int endHour = int.tryParse(endTimeParts[0]) ?? 0;
      int endMinute = int.tryParse(endTimeParts[1]) ?? 0;
      int endMinutes = endHour * 60 + endMinute;

      List<String> closedPosts = [];

      // Check each selected condition
      for (String condition in selectedConditions) {
        // Find post for this condition
        ClosingTimePost? post = closingTime.posts.firstWhere(
          (p) => p.postId.toUpperCase() == condition.toUpperCase(),
          orElse: () => ClosingTimePost(
            id: 0,
            postId: '',
            closingTimeId: null,
            vip: false,
            hasActions: false,
          ),
        );

        // If post found, check if it's closed
        if (post.id != 0) {
          // Get day-specific time from closing_time_posts (monday, tuesday, etc.)
          // This is when betting starts/closes for this post on this day
          String? daySpecificTimeStr;
          switch (dayName) {
            case 'monday':
              daySpecificTimeStr = post.monday;
              break;
            case 'tuesday':
              daySpecificTimeStr = post.tuesday;
              break;
            case 'wednesday':
              daySpecificTimeStr = post.wednesday;
              break;
            case 'thursday':
              daySpecificTimeStr = post.thursday;
              break;
            case 'friday':
              daySpecificTimeStr = post.friday;
              break;
            case 'saturday':
              daySpecificTimeStr = post.saturday;
              break;
            case 'sunday':
              daySpecificTimeStr = post.sunday;
              break;
          }

          if (daySpecificTimeStr != null && daySpecificTimeStr.isNotEmpty) {
            // Parse day-specific time from closing_time_posts (format: HH:MM:SS or HH:MM)
            // This time represents when betting closes for this post on this day
            List<String> timeParts = daySpecificTimeStr.split(':');
            if (timeParts.length >= 2) {
              int daySpecificHour = int.tryParse(timeParts[0]) ?? 0;
              int daySpecificMinute = int.tryParse(timeParts[1]) ?? 0;
              int daySpecificMinutes = daySpecificHour * 60 + daySpecificMinute;

              // Check if current time is before day-specific start time (too early to bet)
              // Use day-specific time from closing_time_posts as the start time for this post
              bool isBeforeStart = false;
              if (endMinutes < daySpecificMinutes) {
                // End time is on next day (e.g., 06:30 < 10:30)
                // Betting window: day-specific time (e.g., 10:30) to end_time (next day 06:30)
                // Too early if current time < day-specific time AND current time > end time
                isBeforeStart =
                    currentMinutes < daySpecificMinutes &&
                    currentMinutes > endMinutes;
              } else {
                // End time is on same day
                // Too early if current time < day-specific start time
                isBeforeStart = currentMinutes < daySpecificMinutes;
              }

              // Check if current time is after day-specific closing time
              // Post closes at the day-specific time (e.g., monday = 10:30 for this post)
              // After closing time, betting is blocked until end_time from closing_time table
              bool isAfterClosing = false;
              if (endMinutes < daySpecificMinutes) {
                // End time is on next day (e.g., 06:30 < 10:30)
                // Post is closed if current time >= day-specific closing time OR current time <= end time
                isAfterClosing =
                    currentMinutes >= daySpecificMinutes ||
                    currentMinutes <= endMinutes;
              } else {
                // End time is on same day
                // Post is closed if current time >= day-specific closing time AND current time <= end time
                isAfterClosing =
                    currentMinutes >= daySpecificMinutes &&
                    currentMinutes <= endMinutes;
              }

              // Post is closed if:
              // 1. Too early (before day-specific start time from closing_time_posts)
              // 2. After closing time (after day-specific closing time from closing_time_posts)
              if (isBeforeStart || isAfterClosing) {
                closedPosts.add(condition);
              }
            }
          }
        }
      }

      return closedPosts;
    } catch (e) {
      print('Error checking closed posts: $e');
      // If error, allow betting (fail open)
      return [];
    }
  }

  Future<void> _addNewBet() async {
    // Validate inputs
    if (_selectedLotteryTime == null) {
      Get.snackbar(
        'កំហុស',
        'សូមជ្រើសរើសពេលវេលា',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      Get.snackbar(
        'កំហុស',
        'សូមបញ្ចូលឈ្មោះអតិថិជន',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_expandedNumbers.isEmpty) {
      Get.snackbar(
        'កំហុស',
        'សូមបញ្ចូលលេខចាក់',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    int amountPerNumber = int.tryParse(_amountController.text) ?? 0;
    if (amountPerNumber <= 0) {
      Get.snackbar(
        'កំហុស',
        'សូមបញ្ចូលចំនួនប្រាក់',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Get selected conditions and filter out shortcuts
    List<String> selectedConditions = [];
    _checkboxes.forEach((key, value) {
      if (value) selectedConditions.add(key);
    });

    // Filter out shortcut conditions (4P, 7P) - only store actual conditions
    List<String> filteredConditions = selectedConditions
        .where((condition) => !['4P', '7P'].contains(condition))
        .toList();

    if (filteredConditions.isEmpty) {
      Get.snackbar(
        'កំហុស',
        'សូមជ្រើសរើសលក្ខខណ្ឌ',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Check if any selected posts are closed
    List<String> closedPosts = await _checkClosedPosts(
      _selectedLotteryTime!.timeName,
      filteredConditions,
    );

    if (closedPosts.isNotEmpty) {
      // Show alert for each closed post
      String closedPostsStr = closedPosts.join(', ');
      Get.snackbar(
        'បិទហើយ',
        'ឥឡូវនេះបិទសម្រាប់ post $closedPostsStr',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Calculate total amount with new multiplier logic
    // Now calculate multiplier per condition and sum them up
    int multiplier = 0;

    // Determine if bet numbers are 2-digit or 3-digit
    bool isTwoDigit =
        _expandedNumbers.isNotEmpty && _expandedNumbers.first.length == 2;
    bool isThreeDigit =
        _expandedNumbers.isNotEmpty && _expandedNumbers.first.length == 3;

    // Check money limit based on number type (2-digit or 3-digit) and lottery time
    String numberType = isTwoDigit ? '2 លេខ' : (isThreeDigit ? '3 លេខ' : '');
    if (numberType.isNotEmpty) {
      try {
        final moneyLimit = await BetsApi.getMoneyLimit(
          time: _selectedLotteryTime!.timeName,
          numberType: numberType,
        );

        if (moneyLimit != null) {
          // Get all existing bets for the same lottery time and date
          final existingBets = await BetsApi.getAllBetsByDate(
            date: DateTime.now(),
            billType: _selectedBill,
            lotteryTime: _selectedLotteryTime!.timeName,
          );

          // Calculate total amount per number across all existing bets
          Map<String, int> totalAmountPerNumber = {};
          for (var bet in existingBets) {
            final betNumbers = bet['bet_numbers'] as List<dynamic>? ?? [];
            final betAmountPerNumber = bet['amount_per_number'] as int? ?? 0;

            for (var number in betNumbers) {
              final numberStr = number.toString();
              totalAmountPerNumber[numberStr] =
                  (totalAmountPerNumber[numberStr] ?? 0) + betAmountPerNumber;
            }
          }

          // Check each number in the new bet
          for (var number in _expandedNumbers) {
            final existingTotal = totalAmountPerNumber[number] ?? 0;
            final newTotal = existingTotal + amountPerNumber;

            if (newTotal > moneyLimit) {
              Get.snackbar(
                'កំហុស',
                'លេខ $number: ចំនួនប្រាក់លើសពីកម្រិត! សរុបបច្ចុប្បន្ន: ${existingTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛ + ${amountPerNumber.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛ = ${newTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛ > ${moneyLimit.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
              );
              return;
            }
          }
        }
      } catch (e) {
        // If error fetching limit, allow betting (fail open)
        print('Error checking money limit: $e');
      }
    }

    // Check if specific Vietnam lottery times (6:30PM, 7:30PM, and 8:30PM)
    // These times have special multipliers for A (x4/x3) and 4P (x7/x6)
    bool isSpecificVietnamTime =
        _selectedLotteryTime?.timeName == 'យួន 6:30PM' ||
        _selectedLotteryTime?.timeName == 'យួន 7:30PM' ||
        _selectedLotteryTime?.timeName == 'យួន 8:30PM';

    // Check if យួន 1:30PM
    bool isVietnam130PM = _selectedLotteryTime?.timeName == 'យួន 1:30PM';

    // Check if specific vietnam times for Lo condition (10:30AM, 2:30PM, 4:30PM)
    String timeName = _selectedLotteryTime?.timeName ?? '';
    bool isVietnamLoSpecialTime =
        timeName == 'យួន 10:30AM' ||
        timeName == 'យួន 2:30PM' ||
        timeName == 'យួន 4:30PM';

    // Check if specific vietnam times for Lo condition (6:30PM, 7:30PM, 8:30PM)
    bool isVietnamLoHighMultiplierTime =
        timeName == 'យួន 6:30PM' ||
        timeName == 'យួន 7:30PM' ||
        timeName == 'យួន 8:30PM';

    // Calculate multiplier for each selected condition and sum them
    // Use filteredConditions (without 4P/7P shortcuts) since 4P/7P are just shortcuts that auto-select other conditions
    for (String condition in filteredConditions) {
      int conditionMultiplier = 1;

      // Special multipliers logic - check each condition individually
      if (isVietnamLoHighMultiplierTime && condition == 'Lo') {
        // Special condition for យួន 6:30PM, យួន 7:30PM, យួន 8:30PM with Lo
        if (isTwoDigit) {
          conditionMultiplier = 32; // 2-digit: 32 times
        } else if (isThreeDigit) {
          conditionMultiplier = 25; // 3-digit: 25 times
        }
      } else if (isSpecificVietnamTime && condition == 'A') {
        // For យួន 6:30PM, យួន 7:30PM, and យួន 8:30PM with condition A
        if (isTwoDigit) {
          conditionMultiplier = 4; // 2-digit: 4 times
        } else if (isThreeDigit) {
          conditionMultiplier = 3; // 3-digit: 3 times
        }
      } else if (isSpecificVietnamTime && condition == '4P') {
        // For យួន 6:30PM, យួន 7:30PM, and យួន 8:30PM with condition 4P
        if (isTwoDigit) {
          conditionMultiplier = 7; // 2-digit: 7 times
        } else if (isThreeDigit) {
          conditionMultiplier = 6; // 3-digit: 6 times
        }
      } else if (isVietnam130PM && condition == 'Lo') {
        // Special condition for យួន 1:30PM with Lo
        if (isTwoDigit) {
          conditionMultiplier = 20; // 2-digit: 20 times
        } else if (isThreeDigit) {
          conditionMultiplier = 16; // 3-digit: 16 times
        }
      } else if (isVietnamLoSpecialTime && condition == 'Lo') {
        // Special condition for យួន 10:30AM, យួន 2:30PM, យួន 4:30PM with Lo
        if (isTwoDigit) {
          conditionMultiplier = 23; // 2-digit: 23 times
        } else if (isThreeDigit) {
          conditionMultiplier = 19; // 3-digit: 19 times
        }
      } else if (condition == '4P') {
        // Special multipliers for 4P (non-Vietnam or other cases)
        conditionMultiplier = 4;
      } else if (condition == '7P') {
        // Special multipliers for 7P
        conditionMultiplier = 7;
      } else {
        // For all other conditions, multiplier = 1 per condition
        conditionMultiplier = 1;
      }

      multiplier += conditionMultiplier;
    }

    int totalAmount = _expandedNumbers.length * amountPerNumber * multiplier;

    // Create new bet
    BetData newBet = BetData(
      customerName: _nameController.text.trim(),
      lotteryTimeId: _selectedLotteryTime!.id,
      lotteryTime: _selectedLotteryTime!.timeName,
      betPattern: _betNumberController.text.trim(),
      betNumbers: List.from(_expandedNumbers),
      amountPerNumber: amountPerNumber,
      totalAmount: totalAmount,
      selectedConditions:
          filteredConditions, // Use filtered conditions (without 4P/7P)
      multiplier: multiplier,
      billType: _selectedBill,
      createdAt: DateTime.now(),
    );

    // Add to bet list
    setState(() {
      _betList.add(newBet);
      _totalAmount = _calculateTotalAmount();
    });

    // Store in pending bets table and track ID
    try {
      final pendingBet = await BetsService.insertPendingBet(
        customerName: _nameController.text.trim(),
        lotteryTimeId: _selectedLotteryTime!.id,
        lotteryTime: _selectedLotteryTime!.timeName,
        betPattern: _betNumberController.text.trim(),
        betNumbers: List.from(_expandedNumbers),
        amountPerNumber: amountPerNumber,
        totalAmount: totalAmount,
        multiplier: multiplier,
        billType: _selectedBill,
        selectedConditions: filteredConditions,
      );

      // Track the pending bet ID for later payment
      if (pendingBet.id != null) {
        _pendingBetIds.add(pendingBet.id!);

        // Update the bet in the list with the ID from database
        setState(() {
          final index = _betList.length - 1;
          if (index >= 0) {
            // Replace the bet with the one from database (includes ID)
            _betList[index] = pendingBet;
          }
        });
      }
    } catch (e) {
      print('Error storing pending bet: $e');
    }
  }

  /// Handler for "ចាក់ថ្មី" button - clears ALL fields for new customer
  /// Does NOT add bet - only the return button adds bets
  void _onNewBetPressed() {
    // Clear ALL fields - start completely fresh for new customer
    _clearForm();
  }

  void _clearForm() {
    // Clear everything for "ចាក់ថ្មី" button - start fresh
    // Keep selected lottery time - don't clear it
    _nameController.clear();
    _betNumberController.clear();
    _amountController.clear();
    _expandedNumbers.clear();
    // _selectedLotteryTime = null; // Don't clear time - keep it selected
    _checkboxes.updateAll((key, value) => false);
    // Clear display area - bets already inserted to database
    setState(() {
      _betList.clear();
      _pendingBetIds.clear();
      _totalAmount = 0;

      // If in edit mode, also clear edit mode state and display area
      if (_isEditMode) {
        _isEditMode = false;
        _betsToEdit.clear();
        _betBeingEdited = null;
        _editingBetId = null;
        _currentEditIndex = 0;
      }
    });
  }

  void _clearFormPartial() {
    // Only clear bet numbers and amount
    // Keep customer name, time, and conditions for easy adding more numbers
    _betNumberController.clear();
    _amountController.clear();
    _expandedNumbers.clear();
    // DON'T clear name, time, or checkboxes
    setState(() {});
  }

  Future<void> _processPayment() async {
    // Check if in edit mode - get pending bets from _betsToEdit
    if (_isEditMode && _betsToEdit.isNotEmpty) {
      // Get all pending bet IDs from _betsToEdit
      List<int> pendingBetIds = [];
      for (var bet in _betsToEdit) {
        final betId = bet['id'] as int?;
        final source = bet['source'] as String? ?? '';
        if (betId != null && source == 'pending_bets') {
          pendingBetIds.add(betId);
        }
      }

      if (pendingBetIds.isEmpty) {
        Get.snackbar(
          'កំហុស',
          'មិនមានចាក់បាច់សម្រាប់បង់ប្រាក់',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('កំពុងបង់ប្រាក់...'),
              ],
            ),
          );
        },
      );

      try {
        // Move pending bets to bets table
        await BetsService.movePendingBetsToBets(pendingBetIds);

        // Close loading dialog
        Navigator.of(context).pop();

        // Calculate total for success message
        final editTotal = _calculateEditModeTotalAmount();

        // Show success message
        Get.snackbar(
          'ជោគជ័យ',
          'បានបង់ប្រាក់ជោគជ័យ! សរុប: $editTotal ៛',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Exit edit mode after payment
        _exitEditMode();
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show error message
        Get.snackbar(
          'កំហុស',
          'មិនអាចបង់ប្រាក់បាន: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      return;
    }

    // Normal mode - check _betList
    if (_betList.isEmpty) {
      Get.snackbar(
        'កំហុស',
        'មិនមានចាក់បាច់សម្រាប់បង់ប្រាក់',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('កំពុងបង់ប្រាក់...'),
            ],
          ),
        );
      },
    );

    try {
      // Move pending bets to bets table
      if (_pendingBetIds.isNotEmpty) {
        await BetsService.movePendingBetsToBets(_pendingBetIds);
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      Get.snackbar(
        'ជោគជ័យ',
        'បានបង់ប្រាក់ជោគជ័យ! សរុប: $_totalAmount ៛',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Clear bet list and reset form
      setState(() {
        _betList.clear();
        _totalAmount = 0;
        _pendingBetIds.clear();
      });
      _clearForm();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      Get.snackbar(
        'កំហុស',
        'មិនអាចបង់ប្រាក់បាន: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteBet(BetData bet) async {
    // Find all bets for same customer and time
    final betsInGroup = _betList
        .where(
          (b) =>
              b.customerName == bet.customerName &&
              b.lotteryTime == bet.lotteryTime,
        )
        .toList();

    // If multiple bets, show selection list
    if (betsInGroup.length > 1) {
      List<BetData> selectedBets = [];

      final result = await showDialog<List<BetData>>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text(
                  'ជ្រើសរើសចាក់បាច់ដើម្បីលុប',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      children: betsInGroup.map((b) {
                        final isSelected = selectedBets.contains(b);
                        final conditionsDisplay = b.selectedConditions
                            .where(
                              (condition) =>
                                  condition != '4P' && condition != '7P',
                            )
                            .join(' ');

                        return CheckboxListTile(
                          title: Text(
                            b.betPattern,
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${conditionsDisplay.isEmpty ? '' : '$conditionsDisplay '}${b.betPattern} = ${b.amountPerNumber} ៛',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedBets.add(b);
                              } else {
                                selectedBets.remove(b);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('បោះបង់'),
                  ),
                  TextButton(
                    onPressed: selectedBets.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(selectedBets),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text('លុប (${selectedBets.length})'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null || result.isEmpty) return;

      // Delete selected bets
      for (var b in result) {
        await _performDelete(b);
      }
      return;
    }

    // Single bet - show simple confirmation
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'លុបចាក់បាច់',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'តើអ្នកចង់លុបចាក់បាច់នេះទេ?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('បោះបង់'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('លុប'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _performDelete(bet);
    }
  }

  Future<void> _performDelete(BetData bet) async {
    // Check if bet has ID
    if (bet.id == null) {
      Get.snackbar(
        'កំហុស',
        'មិនមាន ID សម្រាប់លុប: ${bet.customerName}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      print('Deleting bet with ID: ${bet.id}');

      // Delete from database
      await BetsService.deletePendingBet(bet.id!);
      print('Successfully deleted bet from database');

      // Remove from UI list
      setState(() {
        _betList.remove(bet);
        _pendingBetIds.remove(bet.id);
        _totalAmount = _calculateTotalAmount();
      });

      // Show success message
      Get.snackbar(
        'ជោគជ័យ',
        'បានលុបចាក់បាច់ជោគជ័យ',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Show error message
      Get.snackbar(
        'កំហុស',
        'មិនអាចលុបចាក់បាច់បាន: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showReceiptPreview() {
    List<BetData> betsToShow = [];
    int totalAmountToShow = 0;
    String? customerName;
    String? lotteryTime;

    // Check if in edit mode - use _betsToEdit
    if (_isEditMode && _betsToEdit.isNotEmpty) {
      // Convert _betsToEdit to BetData objects
      betsToShow = _betsToEdit.map((betMap) {
        return BetData.fromMap(betMap);
      }).toList();

      // Calculate total amount from edited bets
      totalAmountToShow = betsToShow.fold(
        0,
        (sum, bet) => sum + bet.totalAmount,
      );

      // Get customer name and lottery time from first bet
      if (betsToShow.isNotEmpty) {
        customerName = betsToShow.first.customerName;
        lotteryTime = betsToShow.first.lotteryTime;
      }
    } else if (_betList.isNotEmpty) {
      // Use regular _betList
      betsToShow = _betList;
      totalAmountToShow = _totalAmount;
      final firstBet = _betList.first;
      customerName = firstBet.customerName;
      lotteryTime = firstBet.lotteryTime;
    } else {
      Get.snackbar(
        'កំហុស',
        'មិនមានចាក់បាច់សម្រាប់បង្ហាញវិក័យប័ត្រ',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (betsToShow.isEmpty || customerName == null || lotteryTime == null) {
      Get.snackbar(
        'កំហុស',
        'មិនមានចាក់បាច់សម្រាប់បង្ហាញវិក័យប័ត្រ',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.to(
      () => ReceiptPreview(
        betList: betsToShow,
        totalAmount: totalAmountToShow,
        customerName: customerName,
        lotteryTime: lotteryTime,
        billType: _selectedBill,
      ),
    );
  }

  Future<void> _showLotteryTimeDialog() async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          backgroundColor: Colors.white,
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('កំពុងទាញយកពេលវេលា...'),
            ],
          ),
        );
      },
    );

    try {
      final lotteryTimes = await LotteryTimesService.getAllLotteryTimes();

      // Close loading dialog
      Navigator.of(context).pop();

      if (lotteryTimes.isEmpty) {
        Get.snackbar(
          'ព័ត៌មាន',
          'មិនមានពេលវេលាចាក់បាច់',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: const Text(
              'ជ្រើសរើសពេលវេលា',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lotteryTimes.length,
                itemBuilder: (context, index) {
                  final lotteryTime = lotteryTimes[index];
                  return ListTile(
                    title: Text(
                      lotteryTime.timeName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      lotteryTime.timeCategory,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    onTap: () {
                      // Check if time is actually changing
                      final isTimeChanging =
                          _selectedLotteryTime?.id != lotteryTime.id;

                      setState(() {
                        _selectedLotteryTime = lotteryTime;

                        // Clear display area if time is changing (bets already inserted)
                        if (isTimeChanging) {
                          _betList.clear();
                          _pendingBetIds.clear();
                          _totalAmount = 0;
                        }
                      });
                      Navigator.of(context).pop();
                    },
                    selected: _selectedLotteryTime?.id == lotteryTime.id,
                    selectedTileColor: Colors.orange.withOpacity(0.1),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('បិទ'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      Get.snackbar(
        'កំហុស',
        'មិនអាចទាញយកពេលវេលាបាន: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C5F5F),
      resizeToAvoidBottomInset:
          false, // Prevent keyboard from pushing content up
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 1, child: _buildDisplayArea()),
                Expanded(flex: 1, child: _buildInputSection()),
              ],
            ),
          ),
          _buildKeypad(),
          const SizedBox(height: 30), // Free space at bottom
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Calculate total amount: use edit mode total if editing, otherwise use normal total
    final displayTotal = _isEditMode && _betsToEdit.isNotEmpty
        ? _calculateEditModeTotalAmount()
        : _totalAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2C5F5F),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _processPayment,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: const Text(
                'បង់ប្រាក់',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '$displayTotal ៛',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showReceiptPreview,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.print, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to group bets by customer and time
  Map<String, List<BetData>> _groupBetsByCustomerTime() {
    Map<String, List<BetData>> grouped = {};
    for (var bet in _betList) {
      String key = '${bet.customerName}_${bet.lotteryTime}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(bet);
    }
    return grouped;
  }

  Widget _buildDisplayArea() {
    // Show edit mode bets list if in edit mode
    if (_isEditMode && _betsToEdit.isNotEmpty) {
      return _buildEditBetsList();
    }

    // Otherwise show normal bet list
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'សរុប ៖',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '${_isEditMode && _betsToEdit.isNotEmpty ? _calculateEditModeTotalAmount() : _totalAmount} ៛',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_betList.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _groupBetsByCustomerTime().entries.map((entry) {
                    final bets = entry.value;
                    final firstBet = bets.first;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          // Customer name and delete button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  firstBet.customerName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _deleteBet(firstBet),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Lottery time
                          Text(
                            firstBet.lotteryTime,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Show all bets for this customer/time
                          ...bets.map((bet) {
                            final conditionsDisplay = bet.selectedConditions
                                .where(
                                  (condition) =>
                                      condition != '4P' && condition != '7P',
                                )
                                .join(' ');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Text(
                                    conditionsDisplay.isEmpty
                                        ? ''
                                        : '$conditionsDisplay ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  Text(
                                    bet.betPattern,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${bet.amountPerNumber} ៛',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text(
                  'វាយបញ្ចូលលេខចាក់',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF2C5F5F), // Dark teal color
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Take minimum space needed
          children: [
            // Edit mode header
            if (_isEditMode) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: _isSaving ? null : _exitEditMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        minimumSize: const Size(45, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'បោះបង់',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 2),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              // Clear editing state to allow adding new bet
                              setState(() {
                                _editingBetId = null;
                                _betBeingEdited = null;
                                // Keep customer name and time from the group
                                // Clear only bet numbers and amount for new bet
                                _betNumberController.clear();
                                _amountController.clear();
                                _expandedNumbers.clear();
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        minimumSize: const Size(55, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'បន្ថែមថ្មី',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 2),
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveEditedBet(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        minimumSize: const Size(45, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'រក្សាទុក',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
            ],
            _buildTimeButton(),
            const SizedBox(height: 5),
            _buildInputField(
              'ឈ្មោះ',
              'ឈ្មោះអតិថិជន',
              controller: _nameController,
            ),
            const SizedBox(height: 5),
            _buildInputField('លេខចាក់:', '', controller: _betNumberController),
            const SizedBox(height: 5),
            _buildInputField('ចំនួន:', '', controller: _amountController),
            const SizedBox(height: 5),
            _buildDropdownField(),
            const SizedBox(height: 8),
            _buildCheckboxGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    return GestureDetector(
      onTap: _showLotteryTimeDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(8),
          border: _selectedLotteryTime != null
              ? Border.all(color: Colors.orange, width: 2)
              : null,
        ),
        child: Text(
          _selectedLotteryTime?.timeName ?? 'ពេល',
          style: TextStyle(
            color: _selectedLotteryTime != null ? Colors.orange : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint, {
    TextEditingController? controller,
  }) {
    bool isFocused = false;
    if (controller == _nameController) {
      isFocused = _focusedFieldIndex == 0;
    } else if (controller == _betNumberController) {
      isFocused = _focusedFieldIndex == 1;
    } else if (controller == _amountController) {
      isFocused = _focusedFieldIndex == 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () {
            if (controller != null) {
              if (controller == _nameController) {
                _focusedFieldIndex = 0;
              } else if (controller == _betNumberController) {
                _focusedFieldIndex = 1;
              } else if (controller == _amountController) {
                _focusedFieldIndex = 2;
              }
              setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: isFocused
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
            ),
            child: controller != null
                ? TextField(
                    controller: controller,
                    enabled: controller == _nameController
                        ? true
                        : false, // Enable keyboard for name field only
                    decoration: InputDecoration(
                      hintText: hint,
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : Text(
                    hint,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    // Check if Vietnam lottery time (any យួន time)
    bool isVietnamTime = _selectedLotteryTime?.timeCategory == 'vietnam';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'បុង: ល.រ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showBetsBottomSheet(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedBill,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Show A checkbox for ALL យួន times
        if (isVietnamTime) ...[
          const SizedBox(width: 8),
          Column(
            children: [
              const SizedBox(height: 20), // Align with dropdown
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _checkboxes['A'] ?? false,
                      onChanged: (value) {
                        _handleCheckboxChange('A', value ?? false);
                      },
                      activeColor: Colors.orange,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCheckboxGrid() {
    // Check for specific Vietnam lottery times (6:30PM and 7:30PM)
    String timeName = _selectedLotteryTime?.timeName ?? '';

    // For យួន 6:30PM and យួន 7:30PM, show special checkboxes: 4P, B, C, D, Lo
    // (Note: A checkbox is shown in dropdown row for all vietnam times)
    if (timeName == 'យួន 6:30PM' || timeName == 'យួន 7:30PM') {
      return Column(
        children: [
          _buildCheckboxRow(['4P', 'B', 'C']),
          const SizedBox(height: 6),
          _buildCheckboxRow(['D', 'Lo', '']),
        ],
      );
    }

    // Get the category from selected lottery time
    String category = _selectedLotteryTime?.timeCategory ?? 'vietnam';

    switch (category) {
      case 'khmer-vip':
      case 'international':
        return Column(
          children: [
            _buildCheckboxRow(['4P', 'A', 'B']),
            const SizedBox(height: 6),
            _buildCheckboxRow(['C', 'D', '']),
          ],
        );
      case 'thai':
        return Column(
          children: [
            _buildCheckboxRow(['T', '', '']),
          ],
        );
      case 'vietnam':
      default:
        // For all other vietnam times (1:30PM, 2:30PM, 4:30PM, 8:30PM, 10:30AM, etc.)
        // Show all checkboxes: 4P, F, B, 7P, I, C, Lo, N, D
        // (Note: A checkbox is shown in dropdown row)
        return Column(
          children: [
            _buildCheckboxRow(['4P', 'F', 'B']),
            const SizedBox(height: 6),
            _buildCheckboxRow(['7P', 'I', 'C']),
            const SizedBox(height: 6),
            _buildCheckboxRow(['Lo', 'N', 'D']),
          ],
        );
    }
  }

  Widget _buildCheckboxRow(List<String> labels) {
    return Row(
      children: labels.map((label) {
        // Skip empty strings (used for spacing)
        if (label.isEmpty) {
          return const Expanded(child: SizedBox());
        }

        return Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _checkboxes[label] ?? false,
                  onChanged: (value) {
                    _handleCheckboxChange(label, value ?? false);
                  },
                  activeColor: Colors.orange,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2C5F5F), // Dark teal color
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildKeypadRow([
            _buildKeypadButton(
              Icons.arrow_back,
              'Back',
              Colors.red,
              onPressed: _onBackspacePressed,
            ),
            _buildNumberButton('7', onPressed: () => _onKeypadPressed('7')),
            _buildNumberButton('8', onPressed: () => _onKeypadPressed('8')),
            _buildNumberButton('9', onPressed: () => _onKeypadPressed('9')),
            _buildKeypadButton(
              Icons.close,
              '',
              Colors.red,
              onPressed: () => _onKeypadPressed('x'),
            ),
          ]),
          const SizedBox(height: 4),
          _buildKeypadRow([
            _buildKeypadButton(
              Icons.list,
              'បង្ហាញ',
              Colors.red,
              onPressed: () {
                // Navigate to input method screen
                Get.to(() => const InputMethodScreen());
              },
            ),
            _buildNumberButton('4', onPressed: () => _onKeypadPressed('4')),
            _buildNumberButton('5', onPressed: () => _onKeypadPressed('5')),
            _buildNumberButton('6', onPressed: () => _onKeypadPressed('6')),
            _buildNumberButton('>', onPressed: () => _onKeypadPressed('>')),
          ]),
          const SizedBox(height: 4),
          _buildKeypadRow([
            _buildKeypadButton(
              Icons.delete,
              'លុប',
              Colors.red,
              onPressed: () {
                // Handle delete functionality
                debugPrint('Delete pressed');
              },
            ),
            _buildNumberButton('1', onPressed: () => _onKeypadPressed('1')),
            _buildNumberButton('2', onPressed: () => _onKeypadPressed('2')),
            _buildNumberButton('3', onPressed: () => _onKeypadPressed('3')),
            _buildKeypadButton(
              Icons.remove,
              '',
              Colors.red,
              onPressed: () => _onKeypadPressed('-'),
            ),
          ]),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildKeypadButton(
                  Icons.gps_fixed,
                  'ចាក់ថ្មី',
                  Colors.red,
                  onPressed: _onNewBetPressed,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildNumberButton(
                  '0',
                  onPressed: () => _onKeypadPressed('0'),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildKeypadButton(
                  Icons.keyboard_return,
                  '',
                  Colors.red,
                  onPressed: () async {
                    // If in edit mode, check if we're editing or adding new bet
                    if (_isEditMode) {
                      // If editing an existing bet, save it
                      if (_editingBetId != null) {
                        await _saveEditedBet();
                        return;
                      }

                      // If not editing (form is filled), add new bet to the same group
                      if (_selectedLotteryTime != null &&
                          _nameController.text.trim().isNotEmpty &&
                          _expandedNumbers.isNotEmpty &&
                          _amountController.text.isNotEmpty) {
                        // Get selected conditions
                        List<String> currentConditions = [];
                        _checkboxes.forEach((key, value) {
                          if (value) currentConditions.add(key);
                        });
                        List<String> filteredCurrent = currentConditions
                            .where(
                              (condition) => !['4P', '7P'].contains(condition),
                            )
                            .toList();

                        // Must have at least one condition selected
                        if (filteredCurrent.isNotEmpty) {
                          // Add new bet to the same group (same customer/time)
                          await _addBetToEditGroup();
                          return;
                        }
                      }
                      // Otherwise, switch focus
                      _switchFocus();
                      return;
                    }

                    // Normal mode: Check if all required fields are filled
                    if (_selectedLotteryTime != null &&
                        _nameController.text.trim().isNotEmpty &&
                        _expandedNumbers.isNotEmpty &&
                        _amountController.text.isNotEmpty) {
                      // Get selected conditions
                      List<String> currentConditions = [];
                      _checkboxes.forEach((key, value) {
                        if (value) currentConditions.add(key);
                      });
                      List<String> filteredCurrent = currentConditions
                          .where(
                            (condition) => !['4P', '7P'].contains(condition),
                          )
                          .toList();

                      // Must have at least one condition selected
                      if (filteredCurrent.isNotEmpty) {
                        // Always create new bet - simpler!
                        // Each return click = new row in database
                        // UI groups by customer/time automatically
                        int betListLengthBefore = _betList.length;
                        await _addNewBet();

                        // If bet was added, clear only bet numbers and amount
                        // Keep customer name, time, and conditions for easy adding more numbers
                        if (_betList.length > betListLengthBefore) {
                          _clearFormPartial();
                        }
                        return;
                      }
                    }
                    // Otherwise, switch focus
                    _switchFocus();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<Widget> buttons) {
    return Row(
      children: buttons.map((button) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: button,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(
    IconData icon,
    String label,
    Color backgroundColor, {
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (label.isNotEmpty)
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number, {VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange, width: 4),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Show bottom sheet dialog with list of bets
  Future<void> _showBetsBottomSheet() async {
    try {
      // Get selected lottery time name
      final selectedTimeName = _selectedLotteryTime?.timeName;

      // Fetch groups summary (for total_amount)
      final groupsSummary = await BetsApi.getBetGroupsSummary(
        date: DateTime.now(),
        billType: _selectedBill,
        lotteryTime: selectedTimeName,
      );

      // Fetch individual bets (for invoice numbers)
      final allBets = await BetsApi.getAllBetsByDate(
        date: DateTime.now(),
        billType: _selectedBill,
        lotteryTime: selectedTimeName,
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _BetsBottomSheet(
          bets: allBets,
          groupsSummary: groupsSummary,
          onEdit: _enterEditMode,
          lotteryTime: selectedTimeName,
          billType: _selectedBill,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('មិនអាចទាញយកទិន្នន័យបាន: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Build edit bets list (shows all bets to edit in display area)
  Widget _buildEditBetsList() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'កែប្រែភ្នាល់',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _groupBetsToEditByCustomerTime().entries.map((entry) {
                  final bets = entry.value;
                  final firstBet = bets.first;
                  final customerName =
                      firstBet['customer_name'] as String? ?? '';
                  final lotteryTime = firstBet['lottery_time'] as String? ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        // Customer name and lottery time
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customerName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              lotteryTime,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Show all bets for this customer/time
                        ...bets.map((bet) {
                          final betId = bet['id'] as int?;
                          if (betId == null) return const SizedBox.shrink();

                          final isSelected = _editingBetId == betId;
                          final conditions =
                              bet['selected_conditions'] as List<dynamic>? ??
                              [];
                          final conditionsDisplay = conditions
                              .where(
                                (c) =>
                                    c.toString() != '4P' &&
                                    c.toString() != '7P',
                              )
                              .map((c) => c.toString())
                              .join(' ');
                          final betNumbers =
                              bet['bet_numbers'] as List<dynamic>? ?? [];
                          final betPattern = betNumbers.join(', ');
                          final amountPerNumber =
                              bet['amount_per_number'] as int? ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _loadBetIntoForm(
                                      bet,
                                      bets.indexOf(bet),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          conditionsDisplay.isEmpty
                                              ? ''
                                              : '$conditionsDisplay ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            betPattern,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$amountPerNumber ៛',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _deleteBetFromEditGroup(bet),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Group bets to edit by customer name and lottery time
  Map<String, List<Map<String, dynamic>>> _groupBetsToEditByCustomerTime() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var bet in _betsToEdit) {
      final customerName = bet['customer_name'] as String? ?? '';
      final lotteryTime = bet['lottery_time'] as String? ?? '';
      final key = '${customerName}_$lotteryTime';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(bet);
    }
    return grouped;
  }

  /// Load a bet into the form for editing
  Future<void> _loadBetIntoForm(Map<String, dynamic> bet, int index) async {
    final betId = bet['id'] as int?;
    if (betId == null) return;

    // Load lottery time first (async)
    LotteryTime? matchedTime;
    final lotteryTimeName = bet['lottery_time'] as String? ?? '';
    if (lotteryTimeName.isNotEmpty) {
      try {
        final lotteryTimes = await LotteryTimesService.getAllLotteryTimes();
        matchedTime = lotteryTimes.firstWhere(
          (lt) => lt.timeName == lotteryTimeName,
          orElse: () => LotteryTime(
            id: bet['lottery_time_id'] as int? ?? 0,
            timeName: lotteryTimeName,
            timeCategory: 'vietnam',
            sortOrder: 0,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } catch (e) {
        // If fetch fails, create basic LotteryTime
        matchedTime = LotteryTime(
          id: bet['lottery_time_id'] as int? ?? 0,
          timeName: lotteryTimeName,
          timeCategory: 'vietnam',
          sortOrder: 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }

    setState(() {
      _betBeingEdited = bet;
      _editingBetId = betId;
      _currentEditIndex = index;

      // Load customer name
      _nameController.text = bet['customer_name'] as String? ?? '';

      // Load bet pattern (original pattern like "564x", "10>", etc.) instead of expanded numbers
      final betPattern = bet['bet_pattern'] as String? ?? '';
      if (betPattern.isNotEmpty) {
        // Use original pattern from database
        _betNumberController.text = betPattern;
        // Expand the pattern to get expanded numbers for display
        _expandedNumbers = _expandBetNumbers(betPattern);
      } else {
        // Fallback: if bet_pattern is not available, use bet_numbers
        final betNumbers = bet['bet_numbers'] as List<dynamic>? ?? [];
        final betNumbersStr = betNumbers.map((n) => n.toString()).join(', ');
        _betNumberController.text = betNumbersStr;
        _expandedNumbers = betNumbers.map((n) => n.toString()).toList();
      }

      // Load amount per number
      final amountPerNumber = bet['amount_per_number'] as int? ?? 0;
      _amountController.text = amountPerNumber.toString();

      // Load selected conditions into checkboxes
      _checkboxes.updateAll((key, value) => false); // Clear all first
      final selectedConditions =
          bet['selected_conditions'] as List<dynamic>? ?? [];
      for (var condition in selectedConditions) {
        final conditionStr = condition.toString();
        if (_checkboxes.containsKey(conditionStr)) {
          _checkboxes[conditionStr] = true;
        }
      }

      // Load lottery time
      _selectedLotteryTime = matchedTime;
    });
  }

  /// Enter edit mode with selected bets (store all bets, load first into form)
  Future<void> _enterEditMode(List<Map<String, dynamic>> bets) async {
    if (bets.isEmpty) return;

    setState(() {
      _isEditMode = true;
      _betsToEdit = bets;
      _currentEditIndex = 0;
    });

    // Load first bet into form
    await _loadBetIntoForm(bets.first, 0);
  }

  /// Save the edited bet using current form data
  Future<void> _saveEditedBet() async {
    if (_editingBetId == null || _betBeingEdited == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final bet = _betBeingEdited!;
      final betId = _editingBetId!;
      final source = bet['source'] as String? ?? '';

      // Validate inputs (same as _addNewBet)
      if (_selectedLotteryTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('សូមជ្រើសរើសពេលវេលា'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Get form data
      final customerName = _nameController.text.trim();

      if (customerName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('សូមបញ្ចូលឈ្មោះអតិថិជន'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Parse bet numbers (comma-separated) and expand them
      final betNumbersStr = _betNumberController.text.trim();
      final betNumberPatterns = betNumbersStr
          .split(',')
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty)
          .toList();

      // Expand bet numbers (handle patterns like "564x", "10>", etc.)
      List<String> expandedBetNumbers = [];
      for (String pattern in betNumberPatterns) {
        List<String> expanded = _expandBetNumbers(pattern);
        expandedBetNumbers.addAll(expanded);
      }

      if (expandedBetNumbers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('សូមបញ្ចូលលេខចាក់'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Generate bet_pattern from bet_number_patterns (comma-separated string)
      final betPattern = betNumberPatterns.join(', ');

      final amountPerNumberStr = _amountController.text;
      final amountPerNumber = int.tryParse(amountPerNumberStr) ?? 0;

      if (amountPerNumber <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('សូមបញ្ចូលចំនួនប្រាក់'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Check money limit based on number type (2-digit or 3-digit) and lottery time
      bool isTwoDigitForLimit =
          expandedBetNumbers.isNotEmpty && expandedBetNumbers.first.length == 2;
      bool isThreeDigitForLimit =
          expandedBetNumbers.isNotEmpty && expandedBetNumbers.first.length == 3;

      String numberTypeForLimit = isTwoDigitForLimit
          ? '2 លេខ'
          : (isThreeDigitForLimit ? '3 លេខ' : '');
      if (numberTypeForLimit.isNotEmpty && _selectedLotteryTime != null) {
        try {
          final moneyLimit = await BetsApi.getMoneyLimit(
            time: _selectedLotteryTime!.timeName,
            numberType: numberTypeForLimit,
          );

          if (moneyLimit != null) {
            // Get all existing bets for the same lottery time and date
            final existingBets = await BetsApi.getAllBetsByDate(
              date: DateTime.now(),
              billType: _selectedBill,
              lotteryTime: _selectedLotteryTime!.timeName,
            );

            // Calculate total amount per number across all existing bets
            // Exclude the current bet being edited
            Map<String, int> totalAmountPerNumber = {};
            for (var bet in existingBets) {
              final betId = bet['id'] as int?;
              // Skip the current bet being edited
              if (betId == _editingBetId) continue;

              final betNumbers = bet['bet_numbers'] as List<dynamic>? ?? [];
              final betAmountPerNumber = bet['amount_per_number'] as int? ?? 0;

              for (var number in betNumbers) {
                final numberStr = number.toString();
                totalAmountPerNumber[numberStr] =
                    (totalAmountPerNumber[numberStr] ?? 0) + betAmountPerNumber;
              }
            }

            // Check each number in the edited bet
            for (var number in expandedBetNumbers) {
              final existingTotal = totalAmountPerNumber[number] ?? 0;
              final newTotal = existingTotal + amountPerNumber;

              if (newTotal > moneyLimit) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'លេខ $number: ចំនួនប្រាក់លើសពីកម្រិត! សរុបបច្ចុប្បន្ន: ${existingTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛ + ${amountPerNumber.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛ = ${newTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛ > ${moneyLimit.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
                setState(() {
                  _isSaving = false;
                });
                return;
              }
            }
          }
        } catch (e) {
          // If error fetching limit, allow betting (fail open)
          print('Error checking money limit: $e');
        }
      }

      // Get selected conditions from checkboxes
      List<String> selectedConditions = [];
      _checkboxes.forEach((key, value) {
        if (value) selectedConditions.add(key);
      });

      // Filter out shortcut conditions (4P, 7P) - only store actual conditions
      List<String> filteredConditions = selectedConditions
          .where((condition) => !['4P', '7P'].contains(condition))
          .toList();

      if (filteredConditions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('សូមជ្រើសរើសលក្ខខណ្ឌ'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Get lottery time ID and name
      final lotteryTimeId = _selectedLotteryTime?.id;
      final lotteryTimeName = _selectedLotteryTime?.timeName;

      // Check if any selected posts are closed (same as _addNewBet)
      List<String> closedPosts = await _checkClosedPosts(
        lotteryTimeName ?? '',
        filteredConditions,
      );

      if (closedPosts.isNotEmpty) {
        // Show alert for each closed post
        String closedPostsStr = closedPosts.join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('បិទហើយ - ឥឡូវនេះបិទសម្រាប់ post $closedPostsStr'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Calculate total amount with multiplier logic (same as _addNewBet)
      int multiplier = 0;

      // Determine if bet numbers are 2-digit or 3-digit
      bool isTwoDigit =
          expandedBetNumbers.isNotEmpty && expandedBetNumbers.first.length == 2;
      bool isThreeDigit =
          expandedBetNumbers.isNotEmpty && expandedBetNumbers.first.length == 3;

      // Check if specific Vietnam lottery times (6:30PM, 7:30PM, and 8:30PM)
      bool isSpecificVietnamTime =
          lotteryTimeName == 'យួន 6:30PM' ||
          lotteryTimeName == 'យួន 7:30PM' ||
          lotteryTimeName == 'យួន 8:30PM';

      // Check if យួន 1:30PM
      bool isVietnam130PM = lotteryTimeName == 'យួន 1:30PM';

      // Check if specific vietnam times for Lo condition
      bool isVietnamLoSpecialTime =
          lotteryTimeName == 'យួន 10:30AM' ||
          lotteryTimeName == 'យួន 2:30PM' ||
          lotteryTimeName == 'យួន 4:30PM';

      // Check if specific vietnam times for Lo condition (6:30PM, 7:30PM, 8:30PM)
      bool isVietnamLoHighMultiplierTime =
          lotteryTimeName == 'យួន 6:30PM' ||
          lotteryTimeName == 'យួន 7:30PM' ||
          lotteryTimeName == 'យួន 8:30PM';

      // Calculate multiplier for each selected condition and sum them
      for (String condition in filteredConditions) {
        int conditionMultiplier = 1;

        // Special multipliers logic - check each condition individually
        if (isVietnamLoHighMultiplierTime && condition == 'Lo') {
          if (isTwoDigit) {
            conditionMultiplier = 32;
          } else if (isThreeDigit) {
            conditionMultiplier = 25;
          }
        } else if (isSpecificVietnamTime && condition == 'A') {
          if (isTwoDigit) {
            conditionMultiplier = 4;
          } else if (isThreeDigit) {
            conditionMultiplier = 3;
          }
        } else if (isSpecificVietnamTime && condition == '4P') {
          if (isTwoDigit) {
            conditionMultiplier = 7;
          } else if (isThreeDigit) {
            conditionMultiplier = 6;
          }
        } else if (isVietnam130PM && condition == 'Lo') {
          if (isTwoDigit) {
            conditionMultiplier = 20;
          } else if (isThreeDigit) {
            conditionMultiplier = 16;
          }
        } else if (isVietnamLoSpecialTime && condition == 'Lo') {
          if (isTwoDigit) {
            conditionMultiplier = 23;
          } else if (isThreeDigit) {
            conditionMultiplier = 19;
          }
        } else if (condition == '4P') {
          conditionMultiplier = 4;
        } else if (condition == '7P') {
          conditionMultiplier = 7;
        } else {
          conditionMultiplier = 1;
        }

        multiplier += conditionMultiplier;
      }

      // Calculate total amount: expanded numbers count * amount per number * multiplier
      final totalAmount =
          expandedBetNumbers.length * amountPerNumber * multiplier;

      // Update based on source table
      if (source == 'pending_bets') {
        await BetsApi.updatePendingBetFull(
          betId: betId,
          customerName: customerName.isNotEmpty ? customerName : null,
          lotteryTimeId: lotteryTimeId,
          lotteryTime: lotteryTimeName,
          betPattern: betPattern.isNotEmpty ? betPattern : null,
          betNumbers: expandedBetNumbers.isNotEmpty ? expandedBetNumbers : null,
          amountPerNumber: amountPerNumber > 0 ? amountPerNumber : null,
          selectedConditions: filteredConditions.isNotEmpty
              ? filteredConditions
              : null,
          totalAmount: totalAmount > 0 ? totalAmount : null,
          multiplier: multiplier > 0 ? multiplier : null,
        );
      } else if (source == 'bets') {
        await BetsApi.updateBet(
          betId: betId,
          customerName: customerName.isNotEmpty ? customerName : null,
          lotteryTimeId: lotteryTimeId,
          lotteryTime: lotteryTimeName,
          betPattern: betPattern.isNotEmpty ? betPattern : null,
          betNumbers: expandedBetNumbers.isNotEmpty ? expandedBetNumbers : null,
          amountPerNumber: amountPerNumber > 0 ? amountPerNumber : null,
          selectedConditions: filteredConditions.isNotEmpty
              ? filteredConditions
              : null,
          totalAmount: totalAmount > 0 ? totalAmount : null,
          multiplier: multiplier > 0 ? multiplier : null,
        );
      }

      if (mounted) {
        // Update the bet in the list with new data
        setState(() {
          final betIndex = _betsToEdit.indexWhere(
            (b) => (b['id'] as int?) == betId,
          );
          if (betIndex != -1) {
            // Update the bet with new data
            _betsToEdit[betIndex] = {
              ..._betsToEdit[betIndex],
              'customer_name': customerName,
              'lottery_time_id': lotteryTimeId,
              'lottery_time': lotteryTimeName,
              'bet_pattern': betPattern,
              'bet_numbers': expandedBetNumbers,
              'amount_per_number': amountPerNumber,
              'selected_conditions': filteredConditions,
              'total_amount': totalAmount,
              'multiplier': multiplier,
            };
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('បានកែប្រែជោគជ័យ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មិនអាចកែប្រែបាន: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Delete a bet from edit group
  Future<void> _deleteBetFromEditGroup(Map<String, dynamic> bet) async {
    final betId = bet['id'] as int?;
    final source = bet['source'] as String? ?? '';

    if (betId == null) {
      Get.snackbar(
        'កំហុស',
        'មិនមាន ID សម្រាប់លុប',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'លុបភ្នាល់',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'តើអ្នកចង់លុបភ្នាល់នេះទេ?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('បោះបង់'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('លុប'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      // Delete from database based on source
      if (source == 'pending_bets') {
        await BetsService.deletePendingBet(betId);
      } else if (source == 'bets') {
        await BetsService.deleteBet(betId);
      }

      // Remove from edit list
      setState(() {
        _betsToEdit.removeWhere((b) => (b['id'] as int?) == betId);

        // If the deleted bet was being edited, clear editing state
        if (_editingBetId == betId) {
          _editingBetId = null;
          _betBeingEdited = null;
          _clearFormPartial();
        }
      });

      // Show success message
      Get.snackbar(
        'ជោគជ័យ',
        'បានលុបភ្នាល់ជោគជ័យ',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Show error message
      Get.snackbar(
        'កំហុស',
        'មិនអាចលុបភ្នាល់បាន: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Add a new bet to the edit group (same customer/time)
  Future<void> _addBetToEditGroup() async {
    // Get the first bet from the group to use its customer name and time
    if (_betsToEdit.isEmpty) {
      Get.snackbar(
        'កំហុស',
        'មិនមានភ្នាល់ក្នុងក្រុម',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final firstBet = _betsToEdit.first;
    final groupCustomerName = firstBet['customer_name'] as String? ?? '';
    final groupLotteryTime = firstBet['lottery_time'] as String? ?? '';
    final groupLotteryTimeId = firstBet['lottery_time_id'] as int?;

    // Auto-fill form with group's customer name and time if they don't match
    // This ensures new bets are always added to the same group
    if (_nameController.text.trim() != groupCustomerName ||
        _selectedLotteryTime?.timeName != groupLotteryTime) {
      // Auto-fill with group values
      setState(() {
        _nameController.text = groupCustomerName;
        // Load lottery time if needed
        if (_selectedLotteryTime?.timeName != groupLotteryTime) {
          // Try to load from existing lottery time, otherwise create basic one
          if (groupLotteryTimeId != null && groupLotteryTime.isNotEmpty) {
            // We'll load it in the async part if needed
            _selectedLotteryTime = LotteryTime(
              id: groupLotteryTimeId,
              timeName: groupLotteryTime,
              timeCategory: 'vietnam', // Default, will be updated if needed
              sortOrder: 0,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        }
      });

      // Try to load proper lottery time if we have the ID
      if (groupLotteryTimeId != null) {
        try {
          final lotteryTimes = await LotteryTimesService.getAllLotteryTimes();
          final matchedTime = lotteryTimes.firstWhere(
            (lt) =>
                lt.id == groupLotteryTimeId || lt.timeName == groupLotteryTime,
            orElse: () => LotteryTime(
              id: groupLotteryTimeId,
              timeName: groupLotteryTime,
              timeCategory: 'vietnam',
              sortOrder: 0,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          setState(() {
            _selectedLotteryTime = matchedTime;
          });
        } catch (e) {
          // Keep the basic one we created
          print('Error loading lottery time: $e');
        }
      }
    }

    // Use the same validation and calculation as _addNewBet
    // Get selected conditions and filter out shortcuts
    List<String> selectedConditions = [];
    _checkboxes.forEach((key, value) {
      if (value) selectedConditions.add(key);
    });

    // Filter out shortcut conditions (4P, 7P) - only store actual conditions
    List<String> filteredConditions = selectedConditions
        .where((condition) => !['4P', '7P'].contains(condition))
        .toList();

    if (filteredConditions.isEmpty) {
      Get.snackbar(
        'កំហុស',
        'សូមជ្រើសរើសលក្ខខណ្ឌ',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Check if any selected posts are closed
    List<String> closedPosts = await _checkClosedPosts(
      groupLotteryTime,
      filteredConditions,
    );

    if (closedPosts.isNotEmpty) {
      String closedPostsStr = closedPosts.join(', ');
      Get.snackbar(
        'បិទហើយ',
        'ឥឡូវនេះបិទសម្រាប់ post $closedPostsStr',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Calculate total amount with multiplier logic (same as _addNewBet)
    int multiplier = 0;
    bool isTwoDigit =
        _expandedNumbers.isNotEmpty && _expandedNumbers.first.length == 2;
    bool isThreeDigit =
        _expandedNumbers.isNotEmpty && _expandedNumbers.first.length == 3;

    // Check money limit
    String numberType = isTwoDigit ? '2 លេខ' : (isThreeDigit ? '3 លេខ' : '');
    int amountPerNumber = int.tryParse(_amountController.text) ?? 0;
    if (numberType.isNotEmpty) {
      try {
        final moneyLimit = await BetsApi.getMoneyLimit(
          time: groupLotteryTime,
          numberType: numberType,
        );

        if (moneyLimit != null) {
          // Get all existing bets for the same lottery time and date
          final existingBets = await BetsApi.getAllBetsByDate(
            date: DateTime.now(),
            billType: _selectedBill,
            lotteryTime: groupLotteryTime,
          );

          // Calculate total amount per number across all existing bets
          Map<String, int> totalAmountPerNumber = {};
          for (var bet in existingBets) {
            final betNumbers = bet['bet_numbers'] as List<dynamic>? ?? [];
            final betAmountPerNumber = bet['amount_per_number'] as int? ?? 0;

            for (var number in betNumbers) {
              final numberStr = number.toString();
              totalAmountPerNumber[numberStr] =
                  (totalAmountPerNumber[numberStr] ?? 0) + betAmountPerNumber;
            }
          }

          // Check each number in the new bet
          for (var number in _expandedNumbers) {
            final existingTotal = totalAmountPerNumber[number] ?? 0;
            final newTotal = existingTotal + amountPerNumber;

            if (newTotal > moneyLimit) {
              Get.snackbar(
                'កំហុស',
                'លេខ $number: ចំនួនប្រាក់លើសពីកម្រិត! សរុបបច្ចុប្បន្ន: ${existingTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛ + ${amountPerNumber.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛ = ${newTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛ > ${moneyLimit.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
              );
              return;
            }
          }
        }
      } catch (e) {
        print('Error checking money limit: $e');
      }
    }

    // Check if specific Vietnam lottery times
    bool isSpecificVietnamTime =
        groupLotteryTime == 'យួន 6:30PM' ||
        groupLotteryTime == 'យួន 7:30PM' ||
        groupLotteryTime == 'យួន 8:30PM';
    bool isVietnam130PM = groupLotteryTime == 'យួន 1:30PM';
    bool isVietnamLoSpecialTime =
        groupLotteryTime == 'យួន 10:30AM' ||
        groupLotteryTime == 'យួន 2:30PM' ||
        groupLotteryTime == 'យួន 4:30PM';
    bool isVietnamLoHighMultiplierTime =
        groupLotteryTime == 'យួន 6:30PM' ||
        groupLotteryTime == 'យួន 7:30PM' ||
        groupLotteryTime == 'យួន 8:30PM';

    // Calculate multiplier for each selected condition
    for (String condition in filteredConditions) {
      int conditionMultiplier = 1;

      if (isVietnamLoHighMultiplierTime && condition == 'Lo') {
        conditionMultiplier = isTwoDigit ? 32 : (isThreeDigit ? 25 : 1);
      } else if (isSpecificVietnamTime && condition == 'A') {
        conditionMultiplier = isTwoDigit ? 4 : (isThreeDigit ? 3 : 1);
      } else if (isSpecificVietnamTime && condition == '4P') {
        conditionMultiplier = isTwoDigit ? 7 : (isThreeDigit ? 6 : 1);
      } else if (isVietnam130PM && condition == 'Lo') {
        conditionMultiplier = isTwoDigit ? 20 : (isThreeDigit ? 16 : 1);
      } else if (isVietnamLoSpecialTime && condition == 'Lo') {
        conditionMultiplier = isTwoDigit ? 23 : (isThreeDigit ? 19 : 1);
      } else if (condition == '4P') {
        conditionMultiplier = 4;
      } else if (condition == '7P') {
        conditionMultiplier = 7;
      } else {
        conditionMultiplier = 1;
      }

      multiplier += conditionMultiplier;
    }

    int totalAmount = _expandedNumbers.length * amountPerNumber * multiplier;

    try {
      // Store in pending bets table (same as _addNewBet)
      final pendingBet = await BetsService.insertPendingBet(
        customerName: groupCustomerName,
        lotteryTimeId: groupLotteryTimeId ?? _selectedLotteryTime!.id,
        lotteryTime: groupLotteryTime,
        betPattern: _betNumberController.text.trim(),
        betNumbers: List.from(_expandedNumbers),
        amountPerNumber: amountPerNumber,
        totalAmount: totalAmount,
        multiplier: multiplier,
        billType: _selectedBill,
        selectedConditions: filteredConditions,
      );

      // Add to edit list
      if (pendingBet.id != null) {
        setState(() {
          _betsToEdit.add({
            'id': pendingBet.id,
            'source': 'pending_bets',
            'customer_name': groupCustomerName,
            'lottery_time_id': groupLotteryTimeId ?? _selectedLotteryTime!.id,
            'lottery_time': groupLotteryTime,
            'bet_pattern': _betNumberController.text.trim(),
            'bet_numbers': List.from(_expandedNumbers),
            'amount_per_number': amountPerNumber,
            'total_amount': totalAmount,
            'selected_conditions': filteredConditions,
            'multiplier': multiplier,
          });
        });

        // Clear only bet numbers and amount, keep customer name, time, and conditions
        _clearFormPartial();

        // Show success message
        Get.snackbar(
          'ជោគជ័យ',
          'បានបញ្ចូលភ្នាល់ថ្មីទៅក្នុងក្រុម',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'កំហុស',
        'មិនអាចបញ្ចូលភ្នាល់បាន: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Exit edit mode
  void _exitEditMode() {
    setState(() {
      _isEditMode = false;
      _betsToEdit.clear();
      _betBeingEdited = null;
      _editingBetId = null;
      _currentEditIndex = 0;

      // Clear form
      _nameController.clear();
      _betNumberController.clear();
      _amountController.clear();
      _expandedNumbers.clear();
      _checkboxes.updateAll((key, value) => false);
      _selectedLotteryTime = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _betNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

/// Bottom sheet widget to display list of bets
class _BetsBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> bets;
  final List<Map<String, dynamic>> groupsSummary;
  final Function(List<Map<String, dynamic>>) onEdit;
  final String? lotteryTime;
  final String billType;

  const _BetsBottomSheet({
    required this.bets,
    required this.groupsSummary,
    required this.onEdit,
    required this.lotteryTime,
    required this.billType,
  });

  @override
  State<_BetsBottomSheet> createState() => _BetsBottomSheetState();
}

class _BetsBottomSheetState extends State<_BetsBottomSheet> {
  // State variables for bets and groups summary (can be refreshed)
  late List<Map<String, dynamic>> _bets;
  late List<Map<String, dynamic>> _groupsSummary;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bets = List.from(widget.bets);
    _groupsSummary = List.from(widget.groupsSummary);
  }

  /// Refresh data from database
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch fresh data from database
      final groupsSummary = await BetsApi.getBetGroupsSummary(
        date: DateTime.now(),
        billType: widget.billType,
        lotteryTime: widget.lotteryTime,
      );

      final allBets = await BetsApi.getAllBetsByDate(
        date: DateTime.now(),
        billType: widget.billType,
        lotteryTime: widget.lotteryTime,
      );

      if (mounted) {
        setState(() {
          _bets = allBets;
          _groupsSummary = groupsSummary;
          _isLoading = false;
          // Clear selections after refresh
          _selectedGroups.clear();
          _selectedBetIds.clear();
          _expandedGroups.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មិនអាចទាញយកទិន្នន័យបាន: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Track selected groups (by customer_name + lottery_time key)
  final Set<String> _selectedGroups = {};
  // Track selected individual bets (by bet ID)
  final Set<int> _selectedBetIds = {};
  // Track expanded groups (to show individual bets)
  final Set<String> _expandedGroups = {};
  // Track which bets are being edited
  final Set<int> _editingBetIds = {};
  // Controllers for edit forms
  final Map<int, TextEditingController> _editCustomerNameControllers = {};
  final Map<int, TextEditingController> _editBetNumbersControllers = {};
  final Map<int, TextEditingController> _editAmountPerNumberControllers = {};
  final Map<int, TextEditingController> _editSelectedConditionsControllers = {};
  bool _isProcessing = false;

  /// Group bets by customer name and lottery time
  Map<String, List<Map<String, dynamic>>> _groupBetsByCustomerTime() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var bet in _bets) {
      final customerName = bet['customer_name'] as String? ?? '';
      final lotteryTime = bet['lottery_time'] as String? ?? '';
      final key = '${customerName}_$lotteryTime';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(bet);
    }
    return grouped;
  }

  /// Get group summary data from summary table
  Map<String, dynamic>? _getGroupSummary(
    String customerName,
    String lotteryTime,
  ) {
    try {
      final group = _groupsSummary.firstWhere(
        (g) =>
            g['customer_name'] == customerName &&
            g['lottery_time'] == lotteryTime,
      );
      return group;
    } catch (e) {
      // If not found in summary, return null
      return null;
    }
  }

  /// Calculate totals from individual bets (fallback)
  Map<String, int> _calculateGroupTotals(List<Map<String, dynamic>> bets) {
    int pendingTotal = 0;
    int paidTotal = 0;
    for (var bet in bets) {
      final amount = (bet['total_amount'] as int? ?? 0);
      final source = bet['source'] as String? ?? '';
      if (source == 'pending_bets') {
        pendingTotal += amount;
      } else {
        paidTotal += amount;
      }
    }
    return {
      'pending_total': pendingTotal,
      'paid_total': paidTotal,
      'total': pendingTotal + paidTotal,
    };
  }

  /// Toggle group selection (allow selecting only one group at a time for editing)
  void _toggleGroupSelection(String groupKey) {
    setState(() {
      if (_selectedGroups.contains(groupKey)) {
        // Deselect if already selected
        _selectedGroups.remove(groupKey);
      } else {
        // Clear all selections and select only this one (single selection)
        _selectedGroups.clear();
        _selectedGroups.add(groupKey);
      }
    });
  }

  /// Toggle group expansion (to show individual bets)
  void _toggleGroupExpansion(String groupKey) {
    setState(() {
      if (_expandedGroups.contains(groupKey)) {
        _expandedGroups.remove(groupKey);
      } else {
        _expandedGroups.add(groupKey);
      }
    });
  }

  /// Toggle individual bet selection
  void _toggleBetSelection(int betId) {
    setState(() {
      if (_selectedBetIds.contains(betId)) {
        _selectedBetIds.remove(betId);
        _editingBetIds.remove(betId);
        // Dispose controllers
        _editCustomerNameControllers[betId]?.dispose();
        _editBetNumbersControllers[betId]?.dispose();
        _editAmountPerNumberControllers[betId]?.dispose();
        _editSelectedConditionsControllers[betId]?.dispose();
        _editCustomerNameControllers.remove(betId);
        _editBetNumbersControllers.remove(betId);
        _editAmountPerNumberControllers.remove(betId);
        _editSelectedConditionsControllers.remove(betId);
      } else {
        _selectedBetIds.add(betId);
        _editingBetIds.add(betId);
        // Initialize controllers for this bet
        _initializeEditControllers(betId);
      }
    });
  }

  /// Initialize edit controllers for a bet
  void _initializeEditControllers(int betId) {
    // Find the bet
    final bet = _bets.firstWhere(
      (b) => (b['id'] as int?) == betId,
      orElse: () => {},
    );

    if (bet.isEmpty) return;

    // Initialize controllers if not already initialized
    if (!_editCustomerNameControllers.containsKey(betId)) {
      _editCustomerNameControllers[betId] = TextEditingController(
        text: bet['customer_name'] as String? ?? '',
      );

      // Bet numbers (join array as comma-separated)
      final betNumbers = bet['bet_numbers'] as List<dynamic>? ?? [];
      final betNumbersStr = betNumbers.map((n) => n.toString()).join(', ');
      _editBetNumbersControllers[betId] = TextEditingController(
        text: betNumbersStr,
      );

      // Amount per number
      _editAmountPerNumberControllers[betId] = TextEditingController(
        text: (bet['amount_per_number'] as int? ?? 0).toString(),
      );

      // Selected conditions (join array as comma-separated)
      final selectedConditions =
          bet['selected_conditions'] as List<dynamic>? ?? [];
      final conditionsStr = selectedConditions
          .map((c) => c.toString())
          .where((c) => c.isNotEmpty)
          .join(', ');
      _editSelectedConditionsControllers[betId] = TextEditingController(
        text: conditionsStr,
      );
    }
  }

  /// Calculate total amount for a bet from edit controllers
  int _calculateBetTotal(int betId) {
    final betNumbersStr = _editBetNumbersControllers[betId]?.text ?? '';
    final betNumbers = betNumbersStr
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final amountPerNumberStr =
        _editAmountPerNumberControllers[betId]?.text ?? '0';
    final amountPerNumber = int.tryParse(amountPerNumberStr) ?? 0;

    return betNumbers.length * amountPerNumber;
  }

  /// Save edited bets
  Future<void> _saveEditedBets() async {
    if (_editingBetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('សូមជ្រើសរើសភ្នាល់ដែលអ្នកចង់កែប្រែ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Update each selected bet
      for (var betId in _editingBetIds) {
        final bet = _bets.firstWhere(
          (b) => (b['id'] as int?) == betId,
          orElse: () => {},
        );

        if (bet.isEmpty) continue;

        final source = bet['source'] as String? ?? '';
        final customerName = _editCustomerNameControllers[betId]?.text ?? '';

        // Parse bet numbers (comma-separated)
        final betNumbersStr = _editBetNumbersControllers[betId]?.text ?? '';
        final betNumbers = betNumbersStr
            .split(',')
            .map((n) => n.trim())
            .where((n) => n.isNotEmpty)
            .toList();

        final amountPerNumberStr =
            _editAmountPerNumberControllers[betId]?.text ?? '0';
        final amountPerNumber = int.tryParse(amountPerNumberStr) ?? 0;

        // Parse selected conditions (comma-separated)
        final conditionsStr =
            _editSelectedConditionsControllers[betId]?.text ?? '';
        final selectedConditions = conditionsStr
            .split(',')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();

        // Calculate total amount from bet numbers and amount per number
        final totalAmount = betNumbers.length * amountPerNumber;

        // Update based on source table
        if (source == 'pending_bets') {
          await BetsApi.updatePendingBetFull(
            betId: betId,
            customerName: customerName.isNotEmpty ? customerName : null,
            betNumbers: betNumbers.isNotEmpty ? betNumbers : null,
            amountPerNumber: amountPerNumber > 0 ? amountPerNumber : null,
            selectedConditions: selectedConditions.isNotEmpty
                ? selectedConditions
                : null,
            totalAmount: totalAmount > 0 ? totalAmount : null,
          );
        } else if (source == 'bets') {
          await BetsApi.updateBet(
            betId: betId,
            customerName: customerName.isNotEmpty ? customerName : null,
            betNumbers: betNumbers.isNotEmpty ? betNumbers : null,
            amountPerNumber: amountPerNumber > 0 ? amountPerNumber : null,
            selectedConditions: selectedConditions.isNotEmpty
                ? selectedConditions
                : null,
            totalAmount: totalAmount > 0 ? totalAmount : null,
          );
        }
      }

      if (mounted) {
        // Clear selections and close bottom sheet
        setState(() {
          _selectedBetIds.clear();
          _editingBetIds.clear();
          _selectedGroups.clear();
          _expandedGroups.clear();
        });

        Navigator.of(context).pop(); // Close bottom sheet

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('បានកែប្រែជោគជ័យ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មិនអាចកែប្រែបាន: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Dispose all edit controllers
    for (var controller in _editCustomerNameControllers.values) {
      controller.dispose();
    }
    for (var controller in _editBetNumbersControllers.values) {
      controller.dispose();
    }
    for (var controller in _editAmountPerNumberControllers.values) {
      controller.dispose();
    }
    for (var controller in _editSelectedConditionsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Get all pending bet IDs from selected groups
  List<int> _getSelectedPendingBetIds() {
    final List<int> betIds = [];
    final groupedBets = _groupBetsByCustomerTime();

    for (var selectedKey in _selectedGroups) {
      final groupBets = groupedBets[selectedKey] ?? [];
      for (var bet in groupBets) {
        final betId = bet['id'] as int?;
        final source = bet['source'] as String? ?? '';
        if (betId != null && source == 'pending_bets') {
          betIds.add(betId);
        }
      }
    }

    return betIds;
  }

  /// Get all paid bet IDs from selected groups
  List<int> _getSelectedPaidBetIds() {
    final List<int> betIds = [];
    final groupedBets = _groupBetsByCustomerTime();

    for (var selectedKey in _selectedGroups) {
      final groupBets = groupedBets[selectedKey] ?? [];
      for (var bet in groupBets) {
        final betId = bet['id'] as int?;
        final source = bet['source'] as String? ?? '';
        if (betId != null && source == 'bets') {
          betIds.add(betId);
        }
      }
    }

    return betIds;
  }

  /// Cancel payment for selected groups (move bets back to pending_bets)
  Future<void> _cancelPayment() async {
    final selectedBetIds = _getSelectedPaidBetIds();

    if (selectedBetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('សូមជ្រើសរើសភ្នាល់ដែលអ្នកចង់បោះបង់បង់ប្រាក់'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('កំពុងបោះបង់បង់ប្រាក់...'),
              ],
            ),
          );
        },
      );

      // Move bets back to pending_bets table
      await BetsService.moveBetsToPendingBets(selectedBetIds);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Store count before clearing selections
        final cancelledCount = _selectedGroups.length;

        // Refresh data from database to show updated status
        await _refreshData();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('បានបោះបង់បង់ប្រាក់ជោគជ័យ! ចំនួន: $cancelledCount'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មិនអាចបោះបង់បង់ប្រាក់បាន: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedGroups.clear();
        });
      }
    }
  }

  /// Process payment for selected groups
  Future<void> _processPayment() async {
    final selectedBetIds = _getSelectedPendingBetIds();

    if (selectedBetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('សូមជ្រើសរើសភ្នាល់ដែលអ្នកចង់បង់ប្រាក់'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('កំពុងបង់ប្រាក់...'),
              ],
            ),
          );
        },
      );

      // Move pending bets to bets table
      await BetsService.movePendingBetsToBets(selectedBetIds);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Store count before clearing selections
        final paidCount = _selectedGroups.length;

        // Refresh data from database to show updated status
        await _refreshData();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('បានបង់ប្រាក់ជោគជ័យ! ចំនួន: $paidCount'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មិនអាចបង់ប្រាក់បាន: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedGroups.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while refreshing
    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final groupedBets = _groupBetsByCustomerTime();
    final hasPendingBets = _bets.any((bet) => bet['source'] == 'pending_bets');

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2C5F5F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'បញ្ជីភ្នាល់',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
          // List of grouped bets
          Expanded(
            child: groupedBets.isEmpty
                ? const Center(
                    child: Text(
                      'គ្មានទិន្នន័យ',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedBets.length,
                    itemBuilder: (context, groupIndex) {
                      final entry = groupedBets.entries.elementAt(groupIndex);
                      final groupBets = entry.value;
                      final firstBet = groupBets.first;
                      final customerName =
                          firstBet['customer_name'] as String? ?? '';
                      final lotteryTime =
                          firstBet['lottery_time'] as String? ?? '';

                      // Get group summary from table (pre-calculated)
                      final groupSummary = _getGroupSummary(
                        customerName,
                        lotteryTime,
                      );

                      // Calculate totals from individual bets (we need breakdown by pending/paid)
                      final totals = _calculateGroupTotals(groupBets);
                      final pendingTotal = totals['pending_total'] ?? 0;
                      final paidTotal = totals['paid_total'] ?? 0;

                      // Use total_amount from summary table if available (pre-calculated),
                      // otherwise use calculated total
                      final totalAmount = groupSummary != null
                          ? (groupSummary['total_amount'] as int? ?? 0)
                          : (totals['total'] ?? 0);

                      // Mark for payment status
                      final hasPending = pendingTotal > 0;
                      final markColor = hasPending
                          ? Colors.orange
                          : Colors.green;

                      // Group key for selection
                      final groupKey = '${customerName}_$lotteryTime';
                      final isSelected = _selectedGroups.contains(groupKey);
                      final isExpanded = _expandedGroups.contains(groupKey);

                      return Column(
                        children: [
                          // Group header (tap to select group, double tap or icon to expand)
                          GestureDetector(
                            onTap: () => _toggleGroupSelection(groupKey),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? markColor.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? markColor : markColor,
                                  width: isSelected ? 3 : 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // First row: Mark, invoice number, customer name, lottery time, total amount
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Left side: Checkbox, Mark, invoice number, customer name, lottery time
                                      Expanded(
                                        child: Row(
                                          children: [
                                            // Checkbox for pending groups
                                            // Checkbox for selection (any group)
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (value) =>
                                                  _toggleGroupSelection(
                                                    groupKey,
                                                  ),
                                              activeColor: markColor,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            const SizedBox(width: 8),
                                            // Mark indicator
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: markColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Invoice number, customer name and time
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  // Invoice number from group summary
                                                  if (groupSummary != null &&
                                                      (groupSummary['invoice_number']
                                                                  as String? ??
                                                              '')
                                                          .isNotEmpty) ...[
                                                    Text(
                                                      groupSummary['invoice_number']
                                                              as String? ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF2C5F5F,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  Flexible(
                                                    child: Text(
                                                      customerName,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (lotteryTime
                                                      .isNotEmpty) ...[
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        lotteryTime,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                          fontSize: 12,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Right side: Total amount and expand icon
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${_formatAmount(totalAmount)} ៛',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: markColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              isExpanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color: markColor,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _toggleGroupExpansion(groupKey),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Second row: Payment status text
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: hasPending ? 56 : 24,
                                      ), // Align with checkbox + mark + spacing if pending, otherwise just mark + spacing
                                      Text(
                                        hasPending
                                            ? 'មិនទាន់បង់ប្រាក់'
                                            : 'បានបង់ប្រាក់រួចហើយ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: markColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Individual bets list (when expanded)
                          if (isExpanded) ...[
                            ...groupBets.map((bet) {
                              final betId = bet['id'] as int?;
                              final source = bet['source'] as String? ?? '';
                              final isPending = source == 'pending_bets';
                              final invoiceNumber =
                                  bet['invoice_number'] as String? ?? '';
                              final isBetSelected =
                                  betId != null &&
                                  _selectedBetIds.contains(betId);
                              final isBetEditing =
                                  betId != null &&
                                  _editingBetIds.contains(betId);

                              if (betId == null) return const SizedBox.shrink();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isBetSelected
                                      ? markColor.withOpacity(0.05)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isBetSelected
                                        ? markColor
                                        : (isPending
                                              ? Colors.orange.shade300
                                              : Colors.green.shade300),
                                    width: isBetSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Bet header with checkbox
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: isBetSelected,
                                              onChanged: (value) =>
                                                  _toggleBetSelection(betId),
                                              activeColor: markColor,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              invoiceNumber.isNotEmpty
                                                  ? 'ល.រ: $invoiceNumber'
                                                  : 'ID: $betId',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPending
                                                ? Colors.orange.shade100
                                                : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            isPending
                                                ? 'មិនទាន់បង់ប្រាក់'
                                                : 'បានបង់ប្រាក់រួចហើយ',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isPending
                                                  ? Colors.orange.shade900
                                                  : Colors.green.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Edit form (inline, shown when bet is selected)
                                    if (isBetEditing) ...[
                                      const SizedBox(height: 12),
                                      const Divider(),
                                      const SizedBox(height: 12),
                                      // Customer name
                                      TextField(
                                        controller:
                                            _editCustomerNameControllers[betId],
                                        decoration: const InputDecoration(
                                          labelText: 'ឈ្មោះអតិថិជន',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.all(12),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Selected conditions
                                      TextField(
                                        controller:
                                            _editSelectedConditionsControllers[betId],
                                        decoration: const InputDecoration(
                                          labelText: 'Conditions (ចែកដោយកាត់)',
                                          hintText: '4P, 7P',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.all(12),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Bet numbers
                                      TextField(
                                        controller:
                                            _editBetNumbersControllers[betId],
                                        onChanged: (_) => setState(() {}),
                                        decoration: const InputDecoration(
                                          labelText: 'លេខភ្នាល់ (ចែកដោយកាត់)',
                                          hintText: '12, 34, 56',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.all(12),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Amount per number and total
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  _editAmountPerNumberControllers[betId],
                                              keyboardType:
                                                  TextInputType.number,
                                              onChanged: (_) => setState(() {}),
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'ចំនួនទឹកប្រាក់ក្នុងមួយលេខ',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                                contentPadding: EdgeInsets.all(
                                                  12,
                                                ),
                                                suffixText: '៛',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Calculated total (read-only)
                                          Container(
                                            width: 120,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'សរុប',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${_calculateBetTotal(betId).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2C5F5F),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ],
                      );
                    },
                  ),
          ),
          // Edit and Pay buttons (if groups are selected)
          if (_selectedGroups.isNotEmpty)
            Builder(
              builder: (context) {
                // Only allow editing if exactly one group is selected
                final isSingleGroupSelected = _selectedGroups.length == 1;

                if (!isSingleGroupSelected) {
                  // If multiple groups selected, don't show Edit button
                  final groupedBets = _groupBetsByCustomerTime();
                  bool hasPendingBets = false;
                  bool hasPaidBets = false;

                  // Check if any selected groups have pending bets (for Pay button)
                  for (var selectedKey in _selectedGroups) {
                    final groupBets = groupedBets[selectedKey] ?? [];
                    if (groupBets.any(
                      (bet) =>
                          (bet['source'] as String? ?? '') == 'pending_bets',
                    )) {
                      hasPendingBets = true;
                    }
                    if (groupBets.any(
                      (bet) => (bet['source'] as String? ?? '') == 'bets',
                    )) {
                      hasPaidBets = true;
                    }
                  }

                  // Show Pay and Cancel Payment buttons for multiple selections
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Pay button (only for groups with pending bets)
                          if (hasPendingBets) ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isProcessing || _selectedGroups.isEmpty
                                    ? null
                                    : _processPayment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C5F5F),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isProcessing
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.payment,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'បង់ប្រាក់ (${_selectedGroups.length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                          // Cancel Payment button (only for groups with paid bets)
                          if (hasPaidBets) ...[
                            if (hasPendingBets) const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isProcessing || _selectedGroups.isEmpty
                                    ? null
                                    : _cancelPayment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isProcessing
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.cancel,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'បោះបង់បង់ប្រាក់ (${_selectedGroups.length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                // Single group selected - check if it has pending bets (unpaid)
                final groupedBets = _groupBetsByCustomerTime();
                final selectedKey = _selectedGroups.first;
                final groupBets = groupedBets[selectedKey] ?? [];

                // Only collect pending bets (unpaid)
                final pendingBets = groupBets.where((bet) {
                  final source = bet['source'] as String? ?? '';
                  return source == 'pending_bets';
                }).toList();

                final hasPendingBetsToEdit = pendingBets.isNotEmpty;

                // Check if any selected groups have pending bets (for Pay button)
                bool hasPendingBets = false;
                for (var key in _selectedGroups) {
                  final bets = groupedBets[key] ?? [];
                  if (bets.any(
                    (bet) => (bet['source'] as String? ?? '') == 'pending_bets',
                  )) {
                    hasPendingBets = true;
                    break;
                  }
                }

                // Check if any selected groups have paid bets (for Cancel Payment button)
                bool hasPaidBetsForCancel = false;
                for (var key in _selectedGroups) {
                  final bets = groupedBets[key] ?? [];
                  if (bets.any(
                    (bet) => (bet['source'] as String? ?? '') == 'bets',
                  )) {
                    hasPaidBetsForCancel = true;
                    break;
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Edit button - only for single unpaid group (pending bets)
                        if (hasPendingBetsToEdit)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                      // Get only pending bets from selected group (unpaid only)
                                      final groupedBets =
                                          _groupBetsByCustomerTime();
                                      final selectedKey = _selectedGroups.first;
                                      final groupBets =
                                          groupedBets[selectedKey] ?? [];

                                      // Only add pending bets (unpaid)
                                      final betsToEdit = groupBets.where((bet) {
                                        final source =
                                            bet['source'] as String? ?? '';
                                        return source == 'pending_bets';
                                      }).toList();

                                      if (betsToEdit.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'គ្មានទិន្នន័យដើម្បីកែប្រែ',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      // Close bottom sheet and call onEdit
                                      // Only unpaid bets (pending_bets) are passed
                                      Navigator.of(context).pop();
                                      widget.onEdit(betsToEdit);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'កែប្រែ (${pendingBets.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Save button (only shown when bets are being edited)
                        if (_editingBetIds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _saveEditedBets,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'រក្សាទុក',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                        // Pay button (only for groups with pending bets)
                        if (hasPendingBets) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isProcessing || _selectedGroups.isEmpty
                                  ? null
                                  : _processPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C5F5F),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.payment,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'បង់ប្រាក់ (${_selectedGroups.length})',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                        // Cancel Payment button (only for paid groups)
                        if (hasPaidBetsForCancel) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isProcessing || _selectedGroups.isEmpty
                                  ? null
                                  : _cancelPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.cancel,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'បោះបង់បង់ប្រាក់ (${_selectedGroups.length})',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

/// Edit bets dialog widget
class _EditBetsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> bets;
  final VoidCallback onSaved;

  const _EditBetsDialog({required this.bets, required this.onSaved});

  @override
  State<_EditBetsDialog> createState() => _EditBetsDialogState();
}

class _EditBetsDialogState extends State<_EditBetsDialog> {
  final Map<int, TextEditingController> _customerNameControllers = {};
  final Map<int, TextEditingController> _betNumbersControllers = {};
  final Map<int, TextEditingController> _amountPerNumberControllers = {};
  final Map<int, TextEditingController> _selectedConditionsControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each bet
    for (var bet in widget.bets) {
      final betId = bet['id'] as int?;
      if (betId != null) {
        _customerNameControllers[betId] = TextEditingController(
          text: bet['customer_name'] as String? ?? '',
        );

        // Bet numbers (join array as comma-separated)
        final betNumbers = bet['bet_numbers'] as List<dynamic>? ?? [];
        final betNumbersStr = betNumbers.map((n) => n.toString()).join(', ');
        _betNumbersControllers[betId] = TextEditingController(
          text: betNumbersStr,
        );

        // Amount per number
        _amountPerNumberControllers[betId] = TextEditingController(
          text: (bet['amount_per_number'] as int? ?? 0).toString(),
        );

        // Selected conditions (join array as comma-separated)
        final selectedConditions =
            bet['selected_conditions'] as List<dynamic>? ?? [];
        final conditionsStr = selectedConditions
            .map((c) => c.toString())
            .where((c) => c.isNotEmpty)
            .join(', ');
        _selectedConditionsControllers[betId] = TextEditingController(
          text: conditionsStr,
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _customerNameControllers.values) {
      controller.dispose();
    }
    for (var controller in _betNumbersControllers.values) {
      controller.dispose();
    }
    for (var controller in _amountPerNumberControllers.values) {
      controller.dispose();
    }
    for (var controller in _selectedConditionsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Calculate total amount from bet numbers and amount per number
  int _calculateTotalAmount(int betId) {
    final betNumbersStr = _betNumbersControllers[betId]?.text ?? '';
    final betNumbers = betNumbersStr
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final amountPerNumberStr = _amountPerNumberControllers[betId]?.text ?? '0';
    final amountPerNumber = int.tryParse(amountPerNumberStr) ?? 0;

    return betNumbers.length * amountPerNumber;
  }

  Future<void> _saveEdits() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Update each bet
      for (var bet in widget.bets) {
        final betId = bet['id'] as int?;
        final source = bet['source'] as String? ?? '';

        if (betId == null) continue;

        final customerName = _customerNameControllers[betId]?.text ?? '';

        // Parse bet numbers (comma-separated)
        final betNumbersStr = _betNumbersControllers[betId]?.text ?? '';
        final betNumbers = betNumbersStr
            .split(',')
            .map((n) => n.trim())
            .where((n) => n.isNotEmpty)
            .toList();

        final amountPerNumberStr =
            _amountPerNumberControllers[betId]?.text ?? '0';
        final amountPerNumber = int.tryParse(amountPerNumberStr) ?? 0;

        // Parse selected conditions (comma-separated)
        final conditionsStr = _selectedConditionsControllers[betId]?.text ?? '';
        final selectedConditions = conditionsStr
            .split(',')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();

        // Calculate total amount from bet numbers and amount per number
        final totalAmount = betNumbers.length * amountPerNumber;

        // Update based on source table
        if (source == 'pending_bets') {
          await BetsApi.updatePendingBetFull(
            betId: betId,
            customerName: customerName.isNotEmpty ? customerName : null,
            betNumbers: betNumbers.isNotEmpty ? betNumbers : null,
            amountPerNumber: amountPerNumber > 0 ? amountPerNumber : null,
            selectedConditions: selectedConditions.isNotEmpty
                ? selectedConditions
                : null,
            totalAmount: totalAmount > 0 ? totalAmount : null,
          );
        } else if (source == 'bets') {
          await BetsApi.updateBet(
            betId: betId,
            customerName: customerName.isNotEmpty ? customerName : null,
            betNumbers: betNumbers.isNotEmpty ? betNumbers : null,
            amountPerNumber: amountPerNumber > 0 ? amountPerNumber : null,
            selectedConditions: selectedConditions.isNotEmpty
                ? selectedConditions
                : null,
            totalAmount: totalAmount > 0 ? totalAmount : null,
          );
        }
      }

      if (mounted) {
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('មិនអាចកែប្រែបាន: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'កែប្រែភ្នាល់',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bets list
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.bets.length,
                itemBuilder: (context, index) {
                  final bet = widget.bets[index];
                  final betId = bet['id'] as int?;
                  final source = bet['source'] as String? ?? '';
                  final isPending = source == 'pending_bets';
                  final invoiceNumber = bet['invoice_number'] as String? ?? '';

                  if (betId == null) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPending ? Colors.orange : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bet info header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              invoiceNumber.isNotEmpty
                                  ? 'ល.រ: $invoiceNumber'
                                  : 'ID: $betId',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? Colors.orange.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isPending
                                    ? 'មិនទាន់បង់ប្រាក់'
                                    : 'បានបង់ប្រាក់រួចហើយ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isPending
                                      ? Colors.orange.shade900
                                      : Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Customer name field
                        TextField(
                          controller: _customerNameControllers[betId],
                          decoration: const InputDecoration(
                            labelText: 'ឈ្មោះអតិថិជន',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Selected conditions field
                        TextField(
                          controller: _selectedConditionsControllers[betId],
                          decoration: const InputDecoration(
                            labelText: 'Conditions (ចែកដោយកាត់)',
                            hintText: '4P, 7P',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Bet numbers field
                        TextField(
                          controller: _betNumbersControllers[betId],
                          onChanged: (_) =>
                              setState(() {}), // Recalculate total
                          decoration: const InputDecoration(
                            labelText: 'លេខភ្នាល់ (ចែកដោយកាត់)',
                            hintText: '12, 34, 56',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Amount per number field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _amountPerNumberControllers[betId],
                                keyboardType: TextInputType.number,
                                onChanged: (_) =>
                                    setState(() {}), // Recalculate total
                                decoration: const InputDecoration(
                                  labelText: 'ចំនួនទឹកប្រាក់ក្នុងមួយលេខ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(12),
                                  suffixText: '៛',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Calculated total (read-only)
                            Container(
                              width: 120,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'សរុប',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_calculateTotalAmount(betId).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} ៛',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C5F5F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEdits,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C5F5F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'រក្សាទុក',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
