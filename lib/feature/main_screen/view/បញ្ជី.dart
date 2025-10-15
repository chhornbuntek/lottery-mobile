import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/បញ្ជី_service.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late ListService _listService;

  @override
  void initState() {
    super.initState();
    _listService = Get.put(ListService());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF2C5F5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
        title: const Text(
          'របាយការណ៍សង្ខេប - ប្រចាំថ្ងៃ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _listService.refreshData();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_listService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2C5F5F)),
          );
        }

        return Column(
          children: [
            _buildDateSection(),
            Expanded(child: _buildReportContent()),
          ],
        );
      }),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Lottery Time Filter
          Row(
            children: [
              const Text(
                'ពេល',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => DropdownButton<String>(
                    value: _listService.selectedLotteryTime.isNotEmpty
                        ? _listService.selectedLotteryTime
                        : null,
                    hint: const Text('ជ្រើសរើសពេល'),
                    isExpanded: true,
                    items: _buildGroupedDropdownItems(),
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue.isNotEmpty) {
                        _listService.updateSelectedLotteryTime(newValue);
                      }
                    },
                    menuMaxHeight: 400, // Increase dropdown height
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date Navigation
          Row(
            children: [
              const Text(
                'កាលបរិច្ឆេទ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 24),
                onPressed: () {
                  _listService.updateSelectedDate(
                    _listService.selectedDate.subtract(const Duration(days: 1)),
                  );
                },
              ),
              Text(
                _listService.getFormattedDate(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 24),
                onPressed: () {
                  _listService.updateSelectedDate(
                    _listService.selectedDate.add(const Duration(days: 1)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return Obx(() {
      if (_listService.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_listService.reportData.isEmpty) {
        return _buildEmptyState();
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalAmountSection(),
            const SizedBox(height: 20),
            _buildLedgerItems(),
            const SizedBox(height: 20),
            _buildDateSeparator(),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'មិនមានទិន្នន័យ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'សូមជ្រើសរើសកាលបរិច្ឆេទផ្សេង',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountSection() {
    return Center(
      child: Text(
        'សរុបទឹកប្រាក់',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildLedgerItems() {
    final totalSummary = _listService.getTotalSummary();

    return Column(
      children: [
        _buildLedgerRow(
          '2D :',
          'សរុប :',
          Colors.blue,
          _formatNumber(totalSummary['total_2digit_bets'] ?? 0),
          _formatNumber(totalSummary['total_bet_amount'] ?? 0),
        ),
        _buildLedgerRow(
          '3D :',
          '',
          Colors.blue,
          _formatNumber(totalSummary['total_3digit_bets'] ?? 0),
          '',
        ),
        const SizedBox(height: 16),
        _buildLedgerRow(
          'សង 2D :',
          '',
          Colors.red,
          _formatNumber(totalSummary['total_2digit_payouts'] ?? 0),
          '',
        ),
        _buildLedgerRow(
          'សង 3D :',
          '',
          Colors.red,
          _formatNumber(totalSummary['total_3digit_payouts'] ?? 0),
          '',
        ),
        const SizedBox(height: 16),
        _buildLedgerRow(
          'សរុបសងភ្ញៀវ :',
          '',
          Colors.green,
          _formatNumber(totalSummary['total_payout'] ?? 0),
          '',
        ),
      ],
    );
  }

  Widget _buildLedgerRow(
    String leftLabel,
    String rightLabel,
    Color color,
    String leftValue,
    String rightValue,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  leftLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  leftValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (rightLabel.isNotEmpty)
            Row(
              children: [
                Text(
                  rightLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rightValue,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator() {
    return Center(
      child: Text(
        _listService.getFormattedDate(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildGroupedDropdownItems() {
    List<DropdownMenuItem<String>> items = [];

    for (var entry in _listService.lotteryTimesGrouped.entries) {
      String category = entry.key;
      List<String> times = entry.value;

      if (times.isNotEmpty) {
        // Add category header
        items.add(
          DropdownMenuItem<String>(
            enabled: false,
            value: '',
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        );

        // Add times under this category
        for (String lotteryTime in times) {
          items.add(
            DropdownMenuItem<String>(
              value: lotteryTime,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(lotteryTime, style: const TextStyle(fontSize: 14)),
              ),
            ),
          );
        }
      }
    }

    print('Total dropdown items created: ${items.length}');
    print('Lottery times grouped: ${_listService.lotteryTimesGrouped}');

    return items;
  }

  String _formatNumber(int number) {
    if (number == 0) return '0';
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
