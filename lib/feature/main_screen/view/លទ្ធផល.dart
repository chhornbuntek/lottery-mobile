import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/លទ្ធផល_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedLotteryTime;
  List<Map<String, dynamic>> _results = [];
  List<String> _lotteryTimes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLotteryTimes();
    _loadResults();
  }

  Future<void> _loadLotteryTimes() async {
    try {
      final times = await ResultService.getLotteryTimes();
      setState(() {
        _lotteryTimes = times;
        if (times.isNotEmpty && _selectedLotteryTime == null) {
          _selectedLotteryTime = times.first;
        }
      });
    } catch (e) {
      print('Error loading lottery times: $e');
    }
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await ResultService.fetchResults(
        date: _selectedDate,
        lotteryTime: _selectedLotteryTime,
      );
      setState(() {
        _isLoading = false;
      });

      // Format results asynchronously
      final formattedResults = await ResultService.formatResultsForDisplay(
        results,
      );
      setState(() {
        _results = formattedResults;
      });
    } catch (e) {
      print('Error loading results: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
          'លទ្ធផល',
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
          _buildDateSection(),
          Expanded(child: _buildResultContent()),
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
      child: Column(
        children: [
          // Lottery Time Dropdown
          Row(
            children: [
              const Text(
                'ពេល',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _showLotteryTimeDropdown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedLotteryTime ?? 'ជ្រើសរើសពេល',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedLotteryTime != null
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date Navigation
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 24),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                  });
                  _loadResults();
                },
              ),
              Text(
                _formatDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 24),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                  _loadResults();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C5F5F)),
        ),
      );
    }

    if (_results.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'មិនមានលទ្ធផល',
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    List<String> twoDigitNumbers = List<String>.from(
      result['twoDigitNumbers'] ?? [],
    );
    List<String> threeDigitNumbers = List<String>.from(
      result['threeDigitNumbers'] ?? [],
    );
    bool hasTwoDigit = result['hasTwoDigit'] ?? false;
    bool hasThreeDigit = result['hasThreeDigit'] ?? false;
    bool isEmpty = !hasTwoDigit && !hasThreeDigit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category letter
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEmpty ? Colors.grey.shade300 : const Color(0xFF2C5F5F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                result['category'] ?? '',
                style: TextStyle(
                  color: isEmpty ? Colors.grey.shade600 : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Numbers section
          Expanded(
            child: isEmpty
                ? Text(
                    'មិនមានលទ្ធផល',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2-digit numbers row
                      if (hasTwoDigit) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '2D',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                children: twoDigitNumbers
                                    .map(
                                      (number) => Text(
                                        number,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                        if (hasThreeDigit) const SizedBox(height: 8),
                      ],
                      // 3-digit numbers row
                      if (hasThreeDigit) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '3D',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                children: threeDigitNumbers
                                    .map(
                                      (number) => Text(
                                        number,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showLotteryTimeDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ជ្រើសរើសពេល',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _lotteryTimes.length,
                itemBuilder: (context, index) {
                  final time = _lotteryTimes[index];
                  return ListTile(
                    title: Text(
                      time,
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedLotteryTime == time
                            ? const Color(0xFF2C5F5F)
                            : Colors.black87,
                        fontWeight: _selectedLotteryTime == time
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: _selectedLotteryTime == time
                        ? const Icon(Icons.check, color: Color(0xFF2C5F5F))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedLotteryTime = time;
                      });
                      Navigator.pop(context);
                      _loadResults();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
