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
import '../../../core/config.dart';
import '../../../core/receipt_image_template.dart';
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

  /// Receipt rows: oldest bet = ល.រ 1, newest bet = last row.
  List<BetData> _betsInReceiptOrder(List<BetData> bets) {
    final ordered = List<BetData>.from(bets);
    ordered.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return ordered;
  }

  /// Show what the user typed (e.g. `234x`), not expanded permutations.
  String _betNumbersDisplayForReceipt(BetData bet) {
    final pattern = bet.betPattern.trim();
    if (pattern.isNotEmpty) return pattern;
    if (bet.betNumbers.isEmpty) return '';
    if (bet.betNumbers.length > 10) {
      return '${bet.betNumbers.take(10).join(', ')}...';
    }
    return bet.betNumbers.join(', ');
  }

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
          _fetchedBetList = _betsInReceiptOrder(widget.betList);
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
          _fetchedBetList = _betsInReceiptOrder(bets);
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
          _fetchedBetList = _betsInReceiptOrder(pendingBets);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching bets: $e');
      setState(() {
        _fetchedBetList = _betsInReceiptOrder(widget.betList);
        _isLoading = false;
      });
    }
  }

  ImageReceiptTemplate get _tpl => SupabaseConfig.imageReceiptTemplate!;

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
          // branch1 / branch3 / branch4 → image receipt; branch2 → code receipt
          : SupabaseConfig.usesImageReceiptTemplate
          ? _buildImageReceiptPreviewBody(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(child: _buildDefaultReceiptCard(context)),
            ),
    );
  }

  double _receiptWidth(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width - 32;
    return maxW < 400.0 ? maxW : 400.0;
  }

  Widget _buildDefaultReceiptCard(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Container(
        width: 400,
        constraints: BoxConstraints(maxWidth: _receiptWidth(context)),
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
    );
  }

  Widget _buildImageReceiptPreviewBody(BuildContext context) {
    if (_fetchedBetList.isEmpty) {
      return const Center(child: Text('មិនមានទិន្នន័យ'));
    }

    final firstBet = _fetchedBetList.first;
    final now = DateTime.now();
    final width = _receiptWidth(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: RepaintBoundary(
          key: _repaintBoundaryKey,
          child: SizedBox(
            width: width,
            child: _buildImageReceipt(firstBet, now, width),
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
          _buildHeader(firstBet, now),
          _buildCustomerInfo(firstBet),
          const SizedBox(height: 24),
          const Divider(thickness: 1),
          const SizedBox(height: 16),
          _buildCodeReceiptBetTable(),
          const SizedBox(height: 24),
          _buildFooter(now),
        ],
      ),
    );
  }

  Widget _buildImageReceipt(
    BetData firstBet,
    DateTime now,
    double width,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImageHeader(firstBet, now),
        _buildImageBetRows(width),
        _buildImageFooter(now),
      ],
    );
  }

  Widget _buildImageHeader(BetData firstBet, DateTime now) {
    final dateStr = '${now.day}/${now.month}/${now.year}';
    final t = _tpl;

    return _buildImageSection(
      asset: t.headerAsset,
      aspectRatio: t.headerAspect,
      overlays: (width, height) => [
        _imageFieldBox(
          rect: t.nameField,
          imageWidth: width,
          imageHeight: height,
          text: firstBet.customerName,
          color: t.headerBarTextColor ?? t.fieldTextColor,
        ),
        _imageFieldBox(
          rect: t.billField,
          imageWidth: width,
          imageHeight: height,
          text: _billNumber(firstBet),
          color: t.headerBarTextColor ?? t.fieldTextColor,
        ),
        _imageFieldBox(
          rect: t.dateField,
          imageWidth: width,
          imageHeight: height,
          text: dateStr,
          color: t.fieldTextColor,
        ),
        _imageFieldBox(
          rect: t.lotteryField,
          imageWidth: width,
          imageHeight: height,
          text: firstBet.lotteryTime,
          color: t.fieldTextColor,
        ),
      ],
    );
  }

  Widget _buildImageFooter(DateTime now) {
    final t = _tpl;

    return _buildImageSection(
      asset: t.footerAsset,
      aspectRatio: t.footerAspect,
      overlays: (width, height) {
        final totalAmount = _calculateTotalAmount();
        final totalText = _formatAmountWithCommas(totalAmount);
        final totalDigits = totalAmount.abs().toString().length;

        return [
          if (t.agentField != null)
            _imageFieldBox(
              rect: t.agentField!,
              imageWidth: width,
              imageHeight: height,
              text: _getCurrentUserName(),
              color: t.footerAgentColor,
              fontWeight: FontWeight.w600,
            ),
          _imageFieldBox(
            rect: t.entryTimeField,
            imageWidth: width,
            imageHeight: height,
            text: _formatCambodiaTime(now),
            color: t.footerEntryTimeColor,
            fontWeight: FontWeight.w600,
          ),
          _imageFieldBox(
            rect: t.totalField,
            imageWidth: width,
            imageHeight: height,
            text: totalText,
            color: t.totalFieldColor,
            digitCount: totalDigits,
            fontWeight: FontWeight.bold,
            alignment: Alignment.center,
          ),
          if (t.branchField != null)
            _imageFieldBox(
              rect: t.branchField!,
              imageWidth: width,
              imageHeight: height,
              text: _getCurrentUserName(),
              color: t.agentTextColor ?? t.fieldTextColor,
              fontWeight: FontWeight.bold,
              paddingLeft: 2,
            ),
        ];
      },
    );
  }

  Widget _buildImageSection({
    required String asset,
    required double aspectRatio,
    required List<Widget> Function(double width, double height) overlays,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / aspectRatio;
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                asset,
                width: width,
                height: height,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.broken_image)),
                  );
                },
              ),
              ...overlays(width, height),
            ],
          ),
        );
      },
    );
  }

  String _billNumber(BetData bet) {
    if (bet.invoiceNumber != null && bet.invoiceNumber!.isNotEmpty) {
      return bet.invoiceNumber!;
    }
    return bet.billType;
  }

  String _formatAmountWithCommas(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  Widget _imageFieldBox({
    required ReceiptFieldRect rect,
    required double imageWidth,
    required double imageHeight,
    required String text,
    Widget? child,
    Color? color,
    int? digitCount,
    FontWeight fontWeight = FontWeight.bold,
    Alignment alignment = Alignment.centerLeft,
    double paddingLeft = 2,
  }) {
    final textColor = color ?? _tpl.fieldTextColor;
    final fontSize = rect.fontSizeFor(digitCount: digitCount);

    return Positioned(
      left: imageWidth * rect.left,
      top: imageHeight * rect.top,
      width: imageWidth * rect.width,
      height: imageHeight * rect.height,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.only(left: paddingLeft),
          child:
              child ??
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignment == Alignment.centerRight
                    ? TextAlign.right
                    : alignment == Alignment.center
                    ? TextAlign.center
                    : TextAlign.left,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: textColor,
                  height: 1.0,
                ),
              ),
        ),
      ),
    );
  }

  /// Bet rows for branch1 / branch3 / branch4 image receipt — styles from [ImageReceiptTemplate].
  Widget _buildImageBetRows(double receiptWidth) {
    final t = _tpl;
    final tableWidth = receiptWidth * 0.96;
    final sideInset = receiptWidth * 0.02;

    return Container(
      color: t.rowBackgroundColor,
      padding: EdgeInsets.fromLTRB(sideInset, 2, sideInset, 2),
      child: Column(
        children: _fetchedBetList.asMap().entries.map((entry) {
          final index = entry.key;
          final bet = entry.value;
          final betNumbersDisplay = _betNumbersDisplayForReceipt(bet);
          final conditionsDisplay = bet.selectedConditions
              .where((condition) => !['4P', '7P'].contains(condition))
              .join(' ');

          return Container(
            key: ValueKey('${t.id}_bet_row_${bet.id}_$index'),
            width: tableWidth,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: t.rowTextColor.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: _buildImageBetRow(
              tableWidth: tableWidth,
              no: '${index + 1}',
              number: betNumbersDisplay,
              amount: '${bet.amountPerNumber}',
              post: conditionsDisplay.isNotEmpty ? conditionsDisplay : '-',
              total: '${bet.totalAmount}',
              numberBold: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageBetRow({
    required double tableWidth,
    required String no,
    required String number,
    required String amount,
    required String post,
    required String total,
    bool numberBold = false,
  }) {
    final t = _tpl;
    final values = [no, number, amount, post, total];
    final weights = [
      FontWeight.w600,
      FontWeight.bold,
      FontWeight.w500,
      FontWeight.w500,
      FontWeight.bold,
    ];
    final sizes = t.fonts.rowColumns;

    return Row(
      children: List.generate(5, (i) {
        final colWidth = tableWidth * t.colFractions[i];
        final colLeftPad = t.rowColumnLeftPad[i];

        if (i == 0) {
          return SizedBox(
            width: colWidth,
            child: Transform.translate(
              offset: Offset(colLeftPad, 0),
              child: Center(
                child: Text(
                  no,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: sizes[i],
                    color: t.rowTextColor,
                    fontWeight: weights[i],
                    height: 1.15,
                  ),
                ),
              ),
            ),
          );
        }

        if (i == 2) {
          return SizedBox(
            width: colWidth,
            child: Transform.translate(
              offset: Offset(colLeftPad, 0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  amount,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: sizes[i],
                    color: t.rowTextColor,
                    fontWeight: weights[i],
                    height: 1.15,
                  ),
                ),
              ),
            ),
          );
        }

        if (i == 1) {
          return SizedBox(
            width: colWidth,
            child: Transform.translate(
              offset: Offset(colLeftPad, 0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  number,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: sizes[i],
                    color: t.rowTextColor,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          );
        }

        if (i == 3) {
          final postFontSize = t.fonts.postFontSizeFor(post);
          return SizedBox(
            width: colWidth,
            child: Transform.translate(
              offset: Offset(colLeftPad, 0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  post,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: postFontSize,
                    color: t.rowTextColor,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          );
        }

        if (i == 4) {
          return SizedBox(
            width: colWidth,
            child: Transform.translate(
              offset: Offset(colLeftPad, 0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  total,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: sizes[i],
                    color: t.rowTextColor,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      }),
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
            SupabaseConfig.receiptLogoAsset,
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
              // _buildInvoiceDetailRowWithColor(
              //   'ស្ថានភាព:',
              //   _fetchedBetList.first.isPaid ? 'បានបង់' : 'មិនទាន់បង់',
              //   _fetchedBetList.first.isPaid ? Colors.green : Colors.orange,
              // ),
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

  /// Bet rows for branch2 code receipt only — not used by image template.
  Widget _buildCodeReceiptBetTable() {
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
                flex: 1,
                child: Text(
                  'No',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
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
                  flex: 1,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
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

  double _capturePixelRatio(double layoutHeight) {
    const targetRatio = 3.0;
    const maxPixels = 8192.0;
    if (layoutHeight * targetRatio <= maxPixels) return targetRatio;
    return maxPixels / layoutHeight;
  }

  /// Captures the full receipt PNG (all bet rows), including content below
  /// the visible scroll area.
  Future<Uint8List?> _captureReceiptPngBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 300));

    final boundary =
        _repaintBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final ratio = _capturePixelRatio(boundary.size.height);
    final image = await boundary.toImage(pixelRatio: ratio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
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

      final Uint8List? pngBytes = await _captureReceiptPngBytes();

      if (pngBytes == null) {
        Navigator.of(context).pop();
        Get.snackbar(
          'កំហុស',
          'មិនអាចរក្សាទុកបាន - សូមព្យាយាមម្តងទៀត',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

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
