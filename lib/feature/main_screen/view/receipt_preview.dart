import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/ភ្នាល់_service.dart';

class ReceiptPreview extends StatefulWidget {
  final List<BetData> betList;
  final int totalAmount;

  const ReceiptPreview({
    super.key,
    required this.betList,
    required this.totalAmount,
  });

  @override
  State<ReceiptPreview> createState() => _ReceiptPreviewState();
}

class _ReceiptPreviewState extends State<ReceiptPreview> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  List<BetData> _fetchedBetList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingBets();
  }

  Future<void> _fetchPendingBets() async {
    try {
      final pendingBets = await BetsService.getUserPendingBets();
      print('Fetched ${pendingBets.length} pending bets');
      if (pendingBets.isNotEmpty) {
        print('First bet user name: ${pendingBets.first.userName}');
        print('First bet user ID: ${pendingBets.first.userId}');
        print(
          'First bet selected conditions: ${pendingBets.first.selectedConditions}',
        );
      }
      setState(() {
        _fetchedBetList = pendingBets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching pending bets: $e');
      setState(() {
        _fetchedBetList = widget.betList; // Fallback to passed data
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('វិក័យប័ត្រ'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveReceiptToPhone,
            tooltip: 'រក្សាទុក',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Container(
                    width: 400, // Receipt width
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _buildReceiptWithTemplate(),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildReceiptWithTemplate() {
    return Stack(
      children: [
        // Background template image
        Image.asset(
          'assets/Invoices55555.png',
          width: 400,
          fit: BoxFit.contain,
        ),
        // Overlay data on top of the template
        Positioned.fill(child: _buildDataOverlay()),
      ],
    );
  }

  Widget _buildDataOverlay() {
    if (_fetchedBetList.isEmpty) return const SizedBox.shrink();

    final firstBet = _fetchedBetList.first;
    final now = DateTime.now();

    return Stack(
      children: [
        // Customer Name
        Positioned(
          left: 90,
          top: 80,
          child: Text(
            firstBet.customerName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // Bill Number
        Positioned(
          left: 90,
          top: 110,
          child: const Text(
            'ល.រ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // Date
        Positioned(
          right: 19,
          top: 81,
          child: Text(
            '${now.day}/${now.month}/${now.year}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // Amount in words
        Positioned(
          right: 50,
          top: 175,
          child: Text(
            _formatAmountInWords(_calculateTotalAmount()),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // Selected Conditions (ប៉ុស្តិ៍)
        Positioned(
          left: 170,
          top: 175,
          child: Text(
            firstBet.selectedConditions.join(', '),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // Lottery Time
        Positioned(
          left: 222,
          top: 113,
          child: Text(
            firstBet.lotteryTime,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),

        // Agent Name
        Positioned(
          left: 100,
          bottom: 25,
          child: Text(
            _getCurrentUserName(), // Show current user name
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Created At (Entry Time)
        Positioned(
          left: 65,
          bottom: 55,
          child: Text(
            _formatCambodiaTime(now),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // // Bet table rows - Serial numbers
        // ...widget.betList.asMap().entries.map((entry) {
        //   int index = entry.key;
        //   return Positioned(
        //     left: 30,
        //     top: 200 + (index * 30),
        //     child: Text(
        //       '${index + 1}',
        //       style: const TextStyle(
        //         fontSize: 12,
        //         fontWeight: FontWeight.bold,
        //         color: Colors.black,
        //       ),
        //     ),
        //   );
        // }).toList(),

        // Bet table rows - Bet numbers
        ..._fetchedBetList.asMap().entries.map((entry) {
          int index = entry.key;
          BetData bet = entry.value;
          return Positioned(
            left: 50,
            top: 175 + (index * 30),
            child: Text(
              bet.betPattern,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),

        // Bet table rows - Amount per number
        ..._fetchedBetList.asMap().entries.map((entry) {
          int index = entry.key;
          BetData bet = entry.value;
          return Positioned(
            left: 110,
            top: 175 + (index * 30),
            child: Text(
              '${bet.amountPerNumber}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),

        // Bet table rows - Post/Station
        // ...widget.betList.asMap().entries.map((entry) {
        //   int index = entry.key;
        //   BetData bet = entry.value;
        //   return Positioned(
        //     left: 250,
        //     top: 200 + (index * 30),
        //     child: Text(
        //       bet.billType,
        //       style: const TextStyle(
        //         fontSize: 12,
        //         fontWeight: FontWeight.bold,
        //         color: Colors.black,
        //       ),
        //     ),
        //   );
        // }).toList(),

        // Bet table rows - Total
        // ...widget.betList.asMap().entries.map((entry) {
        //   int index = entry.key;
        //   BetData bet = entry.value;
        //   return Positioned(
        //     left: 150,
        //     top: 200 + (index * 30),
        //     child: Text(
        //       '${bet.totalAmount}',
        //       style: const TextStyle(
        //         fontSize: 12,
        //         fontWeight: FontWeight.bold,
        //         color: Colors.black,
        //       ),
        //     ),
        //   );
        // }).toList(),

        // Total amount
        Positioned(
          right: 50,
          bottom: 55,
          child: Text(
            '${_calculateTotalAmount()} ៛',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  int _calculateTotalAmount() {
    int total = 0;
    for (var bet in _fetchedBetList) {
      total += bet.totalAmount;
    }
    return total;
  }

  String _getCurrentUserName() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Try to get user metadata first
        if (user.userMetadata != null &&
            user.userMetadata!['full_name'] != null) {
          return user.userMetadata!['full_name'];
        }
        if (user.userMetadata != null && user.userMetadata!['name'] != null) {
          return user.userMetadata!['name'];
        }
        // Fallback to email
        if (user.email != null && user.email!.isNotEmpty) {
          return user.email!;
        }
        // Last fallback to user ID
        return user.id;
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return 'User';
  }

  String _formatCambodiaTime(DateTime dateTime) {
    // Convert to Cambodia timezone (UTC+7)
    final cambodiaTime = dateTime.toUtc().add(const Duration(hours: 7));

    // Format with AM/PM
    final hour = cambodiaTime.hour;
    final minute = cambodiaTime.minute.toString().padLeft(2, '0');

    String period = 'AM';
    int displayHour = hour;

    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) {
        displayHour = hour - 12;
      }
    } else if (hour == 0) {
      displayHour = 12;
    }

    return '$displayHour:$minute $period';
  }

  String _formatAmountInWords(int amount) {
    // Simple number to words conversion for Khmer
    if (amount == 0) return 'សូន្យ';

    List<String> units = [
      '',
      'មួយ',
      'ពីរ',
      'បី',
      'បួន',
      'ប្រាំ',
      'ប្រាំមួយ',
      'ប្រាំពីរ',
      'ប្រាំបី',
      'ប្រាំបួន',
    ];
    List<String> tens = [
      '',
      '',
      'ម្ភៃ',
      'សាមសិប',
      'សែសិប',
      'ហាសិប',
      'ហុកសិប',
      'ចិតសិប',
      'ប៉ែតសិប',
      'កៅសិប',
    ];

    if (amount < 10) {
      return units[amount];
    } else if (amount < 100) {
      int ten = amount ~/ 10;
      int unit = amount % 10;
      if (unit == 0) {
        return tens[ten];
      } else {
        return '${tens[ten]}${units[unit]}';
      }
    } else {
      return '$amount'; // For larger numbers, just show the number
    }
  }

  Future<void> _saveReceiptToPhone() async {
    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        Get.snackbar(
          'កំហុស',
          'មិនអាចរក្សាទុកបាន - សូមអនុញ្ញាតការចូលដំណើរការ',
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
                Text('កំពុងរក្សាទុក...'),
              ],
            ),
          );
        },
      );

      // Capture the widget as image
      RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get the directory for saving
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        String fileName =
            'receipt_${DateTime.now().millisecondsSinceEpoch}.png';
        String filePath = '${directory.path}/$fileName';

        File file = File(filePath);
        await file.writeAsBytes(pngBytes);

        // Close loading dialog
        Navigator.of(context).pop();

        Get.snackbar(
          'ជោគជ័យ',
          'បានរក្សាទុកវិក័យប័ត្រ: $filePath',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        // Close loading dialog
        Navigator.of(context).pop();

        Get.snackbar(
          'កំហុស',
          'មិនអាចរក្សាទុកបាន',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      Get.snackbar(
        'កំហុស',
        'មិនអាចរក្សាទុកបាន: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
