import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/កម្រៃ_service.dart';

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  DateTime _selectedDate = DateTime.now();
  CommissionData? _todayCommission;
  CommissionSummary? _commissionSummary;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCommissionData();
  }

  Future<void> _loadCommissionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load commission for selected date
      final selectedDateStr = _selectedDate.toIso8601String().split('T')[0];
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      CommissionData? selectedDateCommission;

      if (selectedDateStr == todayStr) {
        // If selected date is today, use getTodayCommission
        selectedDateCommission = await CommissionsService.getTodayCommission();
      } else {
        // For other dates, we need to implement a method to get commission by date
        // For now, we'll get all commissions and filter
        final allCommissions = await CommissionsService.getUserCommissions();
        try {
          selectedDateCommission = allCommissions.firstWhere(
            (commission) =>
                commission.date.toIso8601String().split('T')[0] ==
                selectedDateStr,
          );
        } catch (e) {
          selectedDateCommission = null;
        }
      }

      // Load commission summary (last 30 days)
      final summary = await CommissionsService.getCommissionSummary();

      setState(() {
        _todayCommission = selectedDateCommission;
        _commissionSummary = summary;
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
    await _loadCommissionData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5F5F), // Dark teal color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
        title: const Text(
          'កម្រៃរបស់',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMainContent()),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C5F5F), // Dark teal color
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildCircularSummary(),
                    const SizedBox(width: 20),
                    Expanded(child: _buildFinancialData()),
                  ],
                ),
              ),
            ),
            _buildDateNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularSummary() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2C5F5F), // Dark teal inner circle
        border: Border.all(color: Colors.yellow, width: 8),
      ),
      child: const Center(
        child: Text(
          'សង្ខេប',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialData() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white, fontSize: 14),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // _buildDataItem(
        //   'ប្រាក់រង្វាន់',
        //   '${_todayCommission?.totalCommissionAmount ?? 0} ៛',
        //   isUnderlined: true,
        // ),
        // const SizedBox(height: 12),
        _buildDataItem(
          'សរុបភ្នាល់',
          '${_todayCommission?.totalBetAmount ?? 0} ៛',
        ),
        const SizedBox(height: 12),
        _buildDataItem('អតិថិជនចាក់', '${_todayCommission?.betCount ?? 0}'),
        const SizedBox(height: 12),
        _buildDataItem(
          'ភ្នាក់ងារចាក់',
          '${_commissionSummary?.uniqueAgentCount ?? 0}',
        ),
        const SizedBox(height: 12),
        _buildDataItem('ឈ្នះ', '${_todayCommission?.totalWinAmount ?? 0} ៛'),
        const SizedBox(height: 12),
        _buildDataItem('ចាញ់', '${_todayCommission?.totalLossAmount ?? 0} ៛'),
      ],
    );
  }

  Widget _buildDataItem(
    String label,
    String value, {
    bool isUnderlined = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label :',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: isUnderlined ? TextDecoration.underline : null,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDateNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5F5F), // Dark teal color
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'KHR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadCommissionData();
            },
          ),
          Text(
            _formatDate(_selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              _loadCommissionData();
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildBottomSection() {
    return Container(
      height: 200,
      color: Colors.white,
      child: const Center(
        child: Text(
          'Additional content area',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}
