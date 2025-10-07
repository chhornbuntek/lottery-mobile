import 'package:flutter/material.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'បញ្ជី របស់',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'មើលលំអិតប្រចាំថ្ងៃ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSection(),
          Expanded(child: _buildListContent()),
        ],
      ),
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
      child: Row(
        children: [
          const Text(
            'ពេល',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 24),
            onPressed: () {
              // Handle previous date
            },
          ),
          const Text(
            '2023-07-02',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 24),
            onPressed: () {
              // Handle next date
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
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
    return Column(
      children: [
        _buildLedgerRow('2D :', 'សរុប :', Colors.blue),
        _buildLedgerRow('3D :', '', Colors.blue),
        const SizedBox(height: 16),
        _buildLedgerRow('សង 2D :', '', Colors.red),
        _buildLedgerRow('សង 3D :', '', Colors.red),
      ],
    );
  }

  Widget _buildLedgerRow(String leftLabel, String rightLabel, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              leftLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          if (rightLabel.isNotEmpty)
            Text(
              rightLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator() {
    return Center(
      child: Text(
        '2023-07-02',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue,
        ),
      ),
    );
  }
}
