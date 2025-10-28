import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/សរុប_service.dart';

class TotalListScreen extends StatefulWidget {
  const TotalListScreen({super.key});

  @override
  State<TotalListScreen> createState() => _TotalListScreenState();
}

class _TotalListScreenState extends State<TotalListScreen> {
  DateTime _selectedDate = DateTime.now();
  List<LotteryTimeWithTotal> _lotteryTimes = [];
  DateSummary? _dateSummary;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLotteryTimeTotals();
  }

  Future<void> _loadLotteryTimeTotals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final lotteryTimes =
          await LotteryTotalsService.getAllLotteryTimesWithTotals(
            date: _selectedDate,
          );
      final summary = await LotteryTotalsService.getDateSummary(
        date: _selectedDate,
      );

      setState(() {
        _lotteryTimes = lotteryTimes;
        _dateSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'មិនអាចទាញយកទិន្នន័យបាន: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadLotteryTimeTotals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5F5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
        title: const Text(
          'បញ្ជីសរុប',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSection(),
          _buildSummarySection(),
          _buildTableHeader(),
          Expanded(child: _buildTableContent()),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 24),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadLotteryTimeTotals();
            },
          ),
          const Spacer(),
          Text(
            _formatDate(_selectedDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 24),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              _loadLotteryTimeTotals();
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildSummarySection() {
    if (_dateSummary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5F5F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'សរុបទឹកលុយ',
            '${_dateSummary!.totalAmount} ៛',
            Icons.account_balance_wallet,
          ),
          _buildSummaryItem(
            'ចំនួនភ្នាល់',
            '${_dateSummary!.totalBetCount}',
            Icons.list_alt,
          ),
          _buildSummaryItem(
            'ពេលវេលា',
            '${_dateSummary!.lotteryTimeCount}',
            Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderText('ពេល')),
          Expanded(flex: 2, child: _buildHeaderText('ទឹកលុយ')),
          Expanded(flex: 2, child: _buildHeaderText('សរុប')),
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTableContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('ព្យាយាមម្តងទៀត'),
            ),
          ],
        ),
      );
    }

    if (_lotteryTimes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_outlined, size: 80, color: Colors.grey.shade400),
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

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        itemCount: _lotteryTimes.length,
        itemBuilder: (context, index) {
          final lotteryTime = _lotteryTimes[index];
          return _buildLotteryTimeRow(lotteryTime, index);
        },
      ),
    );
  }

  Widget _buildLotteryTimeRow(LotteryTimeWithTotal lotteryTime, int index) {
    final isEven = index % 2 == 0;

    return Container(
      color: isEven ? Colors.white : Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              lotteryTime.timeName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${lotteryTime.totalAmount} ៛',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: lotteryTime.totalAmount > 0 ? Colors.green : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${lotteryTime.betCount}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
