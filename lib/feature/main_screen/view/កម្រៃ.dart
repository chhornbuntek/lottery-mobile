import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  String _userName = 'User';
  List<CommissionTimeSlotData> _commissionData = [];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadCommissionData();
  }

  Future<void> _loadUserName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Try to get from profile table first
        try {
          final profile = await Supabase.instance.client
              .from('profile')
              .select('full_name')
              .eq('id', user.id)
              .single();

          if (profile['full_name'] != null) {
            setState(() {
              _userName = profile['full_name'];
            });
            return;
          }
        } catch (e) {
          print('Error fetching profile: $e');
        }

        // Fallback to user metadata
        if (user.userMetadata != null &&
            user.userMetadata!['full_name'] != null) {
          setState(() {
            _userName = user.userMetadata!['full_name'];
          });
          return;
        }
        if (user.userMetadata != null && user.userMetadata!['name'] != null) {
          setState(() {
            _userName = user.userMetadata!['name'];
          });
          return;
        }
        // Fallback to email
        if (user.email != null && user.email!.isNotEmpty) {
          setState(() {
            _userName = user.email!;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  Future<void> _loadCommissionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load commission data with time slots
      final commissionData =
          await CommissionsService.getCommissionDataWithTimeSlots(
            date: _selectedDate,
          );

      // Also load old data for backward compatibility
      final selectedDateStr = _selectedDate.toIso8601String().split('T')[0];
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      CommissionData? selectedDateCommission;

      if (selectedDateStr == todayStr) {
        selectedDateCommission = await CommissionsService.getTodayCommission();
      } else {
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

      final summary = await CommissionsService.getCommissionSummary();

      setState(() {
        _commissionData = commissionData;
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
          _buildUserNameContainer(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildMainContent(),
                  if (!_isLoading) _buildTimeSlotsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserNameContainer() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5F5F), // Dark teal color
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Text(
            'ភ្នាក់ងារ:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCircularSummary(),
                  const SizedBox(width: 20),
                  Expanded(child: _buildFinancialData()),
                ],
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

    // Get summary data from commission data
    final summaryData = _commissionData.firstWhere(
      (data) => data.isSummary,
      orElse: () => CommissionTimeSlotData(
        type: 'summary',
        bonus: _todayCommission?.totalCommissionAmount ?? 0,
        totalBets: _todayCommission?.totalBetAmount ?? 0,
        customerBets: 0,
        agentBets: 0,
        totalPayout: _todayCommission?.totalWinAmount ?? 0,
        winLoss: 0,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDataItem('ប្រាក់រង្វាន់', '${_formatNumber(summaryData.bonus)}៛'),
        const SizedBox(height: 12),
        _buildDataItem(
          'សរុបភ្នាល់',
          '${_formatNumber(summaryData.totalBets)}៛',
        ),
        const SizedBox(height: 12),
        _buildDataItem(
          'អតិថិជនចាក់',
          '${_formatNumber(summaryData.customerBets)}៛',
        ),
        const SizedBox(height: 12),
        _buildDataItem(
          'ភ្នាក់ងារចាក់',
          '${_formatNumber(summaryData.agentBets)}៛',
        ),
        const SizedBox(height: 12),
        _buildDataItem(
          'ឈ្នះចាញ់',
          '${summaryData.winLoss >= 0 ? '+' : ''}${_formatNumber(summaryData.winLoss)}៛',
          valueColor: summaryData.winLoss >= 0 ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildDataItem(
    String label,
    String value, {
    bool isUnderlined = false,
    Color? valueColor,
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
          style: TextStyle(
            color: valueColor ?? Colors.white,
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

  Widget _buildTimeSlotsList() {
    if (_isLoading || _commissionData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter out summary and get only time slots
    final timeSlots = _commissionData.where((data) => data.isTimeSlot).toList();

    if (timeSlots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: timeSlots.map((slot) => _buildTimeSlotCard(slot)).toList(),
      ),
    );
  }

  Widget _buildTimeSlotCard(CommissionTimeSlotData slot) {
    // Determine color based on win/loss
    Color barColor;
    if (slot.winLoss > 0) {
      barColor = Colors.green;
    } else if (slot.winLoss < 0) {
      barColor = Colors.red;
    } else {
      barColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colored bar
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    slot.lotteryTime ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Details row
                  Row(
                    children: [
                      // Left column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTimeSlotDetail(
                              'សរុបភ្នាល់',
                              '${_formatNumber(slot.totalBets)}',
                            ),
                            const SizedBox(height: 8),
                            _buildTimeSlotDetail(
                              'អតិថិជនចាក់',
                              '${_formatNumber(slot.customerBets)}',
                            ),
                            const SizedBox(height: 8),
                            _buildTimeSlotDetail(
                              'ភ្នាក់ងារចាក់',
                              '${_formatNumber(slot.agentBets)}',
                            ),
                            const SizedBox(height: 8),
                            _buildTimeSlotDetail(
                              'សរុបសង',
                              '${_formatNumber(slot.totalPayout)}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Right column - Win/Loss
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            slot.winLoss >= 0 ? 'ឈ្នះ' : 'ចាញ់',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: slot.winLoss >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatNumber(slot.winLoss.abs())}៛',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: slot.winLoss >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label :',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildBottomSection() {
    return const SizedBox.shrink();
  }
}
