import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../service/ភ្នាល់_service.dart';

class ReceiptPreview extends StatefulWidget {
  final List<BetData> betList;
  final int totalAmount;
  final String? customerName;
  final String? lotteryTime;
  final String? billType;

  const ReceiptPreview({
    super.key,
    required this.betList,
    required this.totalAmount,
    this.customerName,
    this.lotteryTime,
    this.billType,
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
      // If betList is provided and not empty, use it directly (especially for edit mode)
      if (widget.betList.isNotEmpty) {
        print('Using provided betList with ${widget.betList.length} bets');
        if (widget.betList.isNotEmpty) {
          print(
            'First bet: numbers=${widget.betList.first.betNumbers.join(",")}, invoiceNumber=${widget.betList.first.invoiceNumber}',
          );
        }
        setState(() {
          _fetchedBetList = widget.betList;
          _isLoading = false;
        });
        return;
      }

      // If customer name and lottery time are provided, use bet_groups_summary
      if (widget.customerName != null &&
          widget.customerName!.isNotEmpty &&
          widget.lotteryTime != null &&
          widget.lotteryTime!.isNotEmpty) {
        final bets = await BetsService.getBetsByGroupSummary(
          customerName: widget.customerName!,
          lotteryTime: widget.lotteryTime!,
          date: DateTime.now(),
          billType: widget.billType,
        );
        print('Fetched ${bets.length} bets from bet_groups_summary');
        if (bets.isNotEmpty) {
          print('First bet user name: ${bets.first.userName}');
          print('First bet user ID: ${bets.first.userId}');
          print(
            'First bet selected conditions: ${bets.first.selectedConditions}',
          );
          for (int i = 0; i < bets.length; i++) {
            print(
              'Bet $i: numbers=${bets[i].betNumbers.join(",")}, amountPerNumber=${bets[i].amountPerNumber}, totalAmount=${bets[i].totalAmount}',
            );
          }
        }
        setState(() {
          _fetchedBetList = bets;
          _isLoading = false;
        });
      } else {
        // Fallback to old method
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
      }
    } catch (e) {
      print('Error fetching bets: $e');
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
                    width: 400, // Fixed receipt width (like a physical receipt)
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width -
                          32, // Responsive max width
                    ),
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
    if (_fetchedBetList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('មិនមានទិន្នន័យ'),
        ),
      );
    }

    final firstBet = _fetchedBetList.first;
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Logo
          _buildHeader(firstBet, now),

          const SizedBox(height: 24),

          // Customer Information
          _buildCustomerInfo(firstBet),

          const SizedBox(height: 24),

          // Divider
          const Divider(thickness: 1),

          const SizedBox(height: 16),

          // Bet Table
          _buildBetTable(),

          const SizedBox(height: 24),

          // Footer
          _buildFooter(now),
        ],
      ),
    );
  }

  Widget _buildHeader(BetData firstBet, DateTime now) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        ClipOval(
          child: Image.asset(
            'assets/logo2.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 40),
              );
            },
          ),
        ),

        const SizedBox(width: 16),

        // Title and Invoice Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'វិក័យប័ត្រ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              _buildInvoiceDetailRow(
                'លេខវិក័យប័ត្រ:',
                firstBet.invoiceNumber ?? 'ល.រ',
              ),
              const SizedBox(height: 4),
              _buildInvoiceDetailRow(
                'កាលបរិច្ឆេទ:',
                '${now.day}/${now.month}/${now.year}',
              ),
              const SizedBox(height: 4),
              _buildInvoiceDetailRow('ម៉ោងឆ្នោត:', firstBet.lotteryTime),
              const SizedBox(height: 4),
              _buildInvoiceDetailRowWithColor(
                'ស្ថានភាព:',
                _fetchedBetList.first.isPaid ? 'បានបង់' : 'មិនទាន់បង់',
                _fetchedBetList.first.isPaid ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInvoiceDetailRowWithColor(
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(BetData firstBet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ចេញចំពោះ:',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          firstBet.customerName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBetTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'លេខភ្នាល់',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'ចំនួន',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'ប៉ុស្តិ៍',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'សរុប',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Table Rows
        ..._fetchedBetList.asMap().entries.map((entry) {
          int index = entry.key;
          BetData bet = entry.value;

          // Format bet numbers
          String betNumbersDisplay = bet.betNumbers.join(', ');
          if (bet.betNumbers.length > 10) {
            betNumbersDisplay = '${bet.betNumbers.take(10).join(', ')}...';
          }

          // Format conditions (filter out 4P and 7P shortcuts)
          final conditionsDisplay = bet.selectedConditions
              .where((condition) => !['4P', '7P'].contains(condition))
              .join(' ');

          return Container(
            key: ValueKey('bet_row_${bet.id}_$index'),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    betNumbersDisplay,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${bet.amountPerNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    conditionsDisplay.isNotEmpty ? conditionsDisplay : '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${bet.totalAmount}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFooter(DateTime now) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5F5F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'សរុប:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${_calculateTotalAmount()} ៛',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Entry Time
          Text(
            'ម៉ោងបញ្ចូល: ${_formatCambodiaTime(now)}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),

          const SizedBox(height: 8),

          // Agent Name
          Text(
            'ភ្នាក់ងារ: ${_getCurrentUserName()}',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
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

  Future<void> _saveReceiptToPhone() async {
    try {
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

      // Wait a bit to ensure widget is fully rendered
      await Future.delayed(const Duration(milliseconds: 500));

      // Capture the widget as image
      final RenderRepaintBoundary? boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        Navigator.of(context).pop();
        Get.snackbar(
          'កំហុស',
          'មិនអាចរក្សាទុកបាន - សូមព្យាយាមម្តងទៀត',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        Navigator.of(context).pop();
        Get.snackbar(
          'កំហុស',
          'មិនអាចបំប្លែងជារូបភាពបាន',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temporary directory first
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'receipt_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '${tempDir.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Request permission and save to gallery
      await Gal.requestAccess();
      await Gal.putImage(file.path);

      // Close loading dialog
      Navigator.of(context).pop();

      // Check if save was successful (gal doesn't throw on success)
      Get.snackbar(
        'ជោគជ័យ',
        'បានរក្សាទុកវិក័យប័ត្រ​ទៅកាន់វិចិត្រសាល',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );

      // Clean up temporary file
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      debugPrint('Error saving receipt: $e');
      Get.snackbar(
        'កំហុស',
        'មិនអាចរក្សាទុកបាន: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}
