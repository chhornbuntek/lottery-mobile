import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/លេខបិទ_service.dart';

class ClosingNumbersScreen extends StatefulWidget {
  const ClosingNumbersScreen({super.key});

  @override
  State<ClosingNumbersScreen> createState() => _ClosingNumbersScreenState();
}

class _ClosingNumbersScreenState extends State<ClosingNumbersScreen> {
  late ClosingNumbersService _closingNumbersService;

  @override
  void initState() {
    super.initState();
    _closingNumbersService = Get.put(ClosingNumbersService());
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
          'លេខបិទ',
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
            onPressed: () {
              _closingNumbersService.refresh();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (_closingNumbersService.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_closingNumbersService.error.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'កំហុសក្នុងការទាញយកទិន្នន័យ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _closingNumbersService.error,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _closingNumbersService.refresh(),
                child: const Text('ព្យាយាមម្តងទៀត'),
              ),
            ],
          ),
        );
      }

      if (_closingNumbersService.closingNumbers.isEmpty) {
        return const Center(
          child: Text(
            'មិនមានទិន្នន័យលេខបិទ',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterSection(),
            const SizedBox(height: 20),
            _buildClosingNumbersList(),
          ],
        ),
      );
    });
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _closingNumbersService.loadClosingNumbers(),
              icon: const Icon(Icons.list, size: 18),
              label: const Text('ទាំងអស់'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade100,
                foregroundColor: Colors.blue.shade800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _closingNumbersService.loadRecentClosingNumbers(),
              icon: const Icon(Icons.schedule, size: 18),
              label: const Text('៧ថ្ងៃកន្លង'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingNumbersList() {
    final groupedByDate = _closingNumbersService
        .getClosingNumbersGroupedByDate();

    return Column(
      children: groupedByDate.entries.map((entry) {
        final date = entry.key;
        final closingNumbers = entry.value;

        return Column(
          children: [
            _buildDateSection(date, closingNumbers),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDateSection(String date, List<ClosingNumber> closingNumbers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${closingNumbers.length} លេខ',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Horizontal scrollable table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: const BoxConstraints(minWidth: 800),
              child: Column(
                children: [
                  _buildTableHeader(),
                  ...closingNumbers.map(
                    (closingNumber) => _buildClosingNumberRow(closingNumber),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            child: Text(
              'ពេលវេលា',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Container(
            width: 100,
            child: Text(
              'លេខបិទ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 120,
            child: Text(
              'ចំនួនទឹកប្រាក់ (៛)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 120,
            child: Text(
              'ចំនួនទឹកប្រាក់ (\$)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 120,
            child: Text(
              'ចំនួនទឹកប្រាក់ (฿)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 100,
            child: Text(
              'កាលបរិច្ឆេទ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingNumberRow(ClosingNumber closingNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            child: Text(
              closingNumber.time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            width: 100,
            child: Text(
              closingNumber.closingNumber,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 120,
            child: Text(
              _closingNumbersService.formatCurrency(
                closingNumber.amountRiel,
                '៛',
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 120,
            child: Text(
              _closingNumbersService.formatCurrency(
                closingNumber.amountDollar,
                '\$',
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 120,
            child: Text(
              _closingNumbersService.formatCurrency(
                closingNumber.amountBaht,
                '฿',
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 100,
            child: Text(
              _formatDate(closingNumber.date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      final months = [
        'មករា',
        'កុម្ភៈ',
        'មីនា',
        'មេសា',
        'ឧសភា',
        'មិថុនា',
        'កក្កដា',
        'សីហា',
        'កញ្ញា',
        'តុលា',
        'វិច្ឆិកា',
        'ធ្នូ',
      ];

      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}
