import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/ភ្នាល់_service.dart';
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
  List<int> _pendingBetIds = []; // Track pending bet IDs
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
          // 2-digit pattern: Sequential range (01-46 = 01, 02, 03, ..., 46)
          int startNum = int.tryParse(start) ?? 0;
          int endNum = int.tryParse(end) ?? 0;

          for (int i = startNum; i <= endNum; i++) {
            expandedNumbers.add(i.toString().padLeft(2, '0'));
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
        // 4P selected: auto select A, B, C, D
        _checkboxes['4P'] = true;
        _checkboxes['A'] = true;
        _checkboxes['B'] = true;
        _checkboxes['C'] = true;
        _checkboxes['D'] = true;
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
        // 4P deselected: uncheck A, B, C, D only if they were auto-selected
        _checkboxes['4P'] = false;
        _checkboxes['A'] = false;
        _checkboxes['B'] = false;
        _checkboxes['C'] = false;
        _checkboxes['D'] = false;
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

    // Calculate total amount with new multiplier logic
    int multiplier = 1;

    // Special multipliers only for 4P and 7P
    if (selectedConditions.contains('4P')) {
      multiplier = 4;
    } else if (selectedConditions.contains('7P')) {
      multiplier = 7;
    } else {
      // Simple logic: number of selected conditions = multiplier
      multiplier = selectedConditions.length;
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
      }
    } catch (e) {
      print('Error storing pending bet: $e');
    }

    // Clear form
    _clearForm();

    // Get.snackbar(
    //   'ជោគជ័យ',
    //   'បានបន្ថែមចាក់បាច់ថ្មី',
    //   backgroundColor: Colors.green,
    //   colorText: Colors.white,
    // );
  }

  void _clearForm() {
    _nameController.clear();
    _betNumberController.clear();
    _amountController.clear();
    _expandedNumbers.clear();
    _selectedLotteryTime = null;
    _checkboxes.updateAll((key, value) => false);
    setState(() {});
  }

  Future<void> _processPayment() async {
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
        return const AlertDialog(
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

  void _showReceiptPreview() {
    if (_betList.isEmpty) {
      Get.snackbar(
        'កំហុស',
        'មិនមានចាក់បាច់សម្រាប់បង្ហាញវិក័យប័ត្រ',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    Get.to(() => ReceiptPreview(betList: _betList, totalAmount: _totalAmount));
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
                      setState(() {
                        _selectedLotteryTime = lotteryTime;
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
      backgroundColor: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              '$_totalAmount ៛',
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

  Widget _buildDisplayArea() {
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
                '$_totalAmount ៛',
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
                  children: _betList.map((bet) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                bet.customerName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bet.lotteryTime,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Show selected conditions (filter out 4P and 7P)
                          Wrap(
                            spacing: 4,
                            children: bet.selectedConditions
                                .where(
                                  (condition) =>
                                      condition != '4P' && condition != '7P',
                                )
                                .map((condition) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      condition,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bet.betPattern,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${bet.amountPerNumber} ៛',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2C5F5F), // Dark teal color
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeButton(),
          const SizedBox(height: 7),
          _buildInputField(
            'ឈ្មោះ',
            'ឈ្មោះអតិថិជន',
            controller: _nameController,
          ),
          const SizedBox(height: 8),
          _buildInputField('លេខចាក់:', '', controller: _betNumberController),
          const SizedBox(height: 8),
          _buildInputField('ចំនួន:', '', controller: _amountController),
          const SizedBox(height: 8),
          _buildDropdownField(),
          const SizedBox(height: 8),
          _buildCheckboxGrid(),
        ],
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
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
              Container(
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
            ],
          ),
        ),
        // Show A checkbox only for Vietnam category
        if (_selectedLotteryTime?.timeCategory == 'vietnam') ...[
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
                  const SizedBox(width: 15),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCheckboxGrid() {
    // Get the category from selected lottery time
    String category = _selectedLotteryTime?.timeCategory ?? 'vietnam';

    switch (category) {
      case 'khmer-vip':
      case 'international':
        return Column(
          children: [
            _buildCheckboxRow(['4P', 'A', 'B']),
            const SizedBox(height: 12),
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
        return Column(
          children: [
            _buildCheckboxRow(['4P', 'F', 'B']),
            const SizedBox(height: 12),
            _buildCheckboxRow(['7P', 'I', 'C']),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2C5F5F), // Dark teal color
      ),
      child: Column(
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
          const SizedBox(height: 5),
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
          const SizedBox(height: 5),
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
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildKeypadButton(
                  Icons.gps_fixed,
                  'ចាក់ថ្មី',
                  Colors.red,
                  onPressed: _addNewBet,
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
                  onPressed: () {
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
        height: 45,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (label.isNotEmpty)
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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
        height: 47,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.orange, width: 5),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _betNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
