import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/ម៉ោងបិទ_service.dart';

// Import ClosingTimePost for type safety

class ClosingTimeScreen extends StatefulWidget {
  const ClosingTimeScreen({super.key});

  @override
  State<ClosingTimeScreen> createState() => _ClosingTimeScreenState();
}

class _ClosingTimeScreenState extends State<ClosingTimeScreen> {
  List<ClosingTime> _closingTimes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClosingTimes();
  }

  Future<void> _loadClosingTimes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔄 Loading closing times from database...');
      final closingTimes = await ClosingTimeService.getAllClosingTimes();
      print('✅ Loaded ${closingTimes.length} closing times from database');

      // Debug: Print details of each closing time
      for (var ct in closingTimes) {
        print('📋 Closing Time: ${ct.timeName}, Posts: ${ct.posts.length}');
        for (var post in ct.posts) {
          print(
            '  - Post ${post.postId}: Mon=${post.monday}, Tue=${post.tuesday}, Wed=${post.wednesday}',
          );
        }
      }

      setState(() {
        _closingTimes = closingTimes;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading closing times: $e');
      setState(() {
        _error = e.toString();
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
          'ម៉ោងបិទ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadClosingTimes,
              child: const Text('ព្យាយាមម្តងទៀត'),
            ),
          ],
        ),
      );
    }

    if (_closingTimes.isEmpty) {
      return const Center(
        child: Text(
          'មិនមានទិន្នន័យម៉ោងបិទ',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClosingTimes,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _closingTimes.map((closingTime) {
            return Column(
              children: [
                _buildScheduleSection(
                  closingTime.timeName,
                  _buildScheduleRows(closingTime),
                ),
                const SizedBox(height: 20),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildScheduleRows(ClosingTime closingTime) {
    if (closingTime.posts.isEmpty) {
      return [];
    }

    return closingTime.posts.map((post) {
      return _buildScheduleRow(
        post.postId,
        _convertToCambodiaTime(_getPostTimeForDay(post, 'monday')),
        _convertToCambodiaTime(_getPostTimeForDay(post, 'tuesday')),
        _convertToCambodiaTime(_getPostTimeForDay(post, 'wednesday')),
        _convertToCambodiaTime(_getPostTimeForDay(post, 'thursday')),
        _convertToCambodiaTime(_getPostTimeForDay(post, 'friday')),
        _convertToCambodiaTime(_getPostTimeForDay(post, 'saturday')),
        _convertToCambodiaTime(_getPostTimeForDay(post, 'sunday')),
      );
    }).toList();
  }

  /// Get time for a specific day from a post
  String? _getPostTimeForDay(ClosingTimePost post, String dayOfWeek) {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        return post.monday;
      case 'tuesday':
        return post.tuesday;
      case 'wednesday':
        return post.wednesday;
      case 'thursday':
        return post.thursday;
      case 'friday':
        return post.friday;
      case 'saturday':
        return post.saturday;
      case 'sunday':
        return post.sunday;
      default:
        return null;
    }
  }

  /// Convert international time to Cambodia time with AM/PM format
  String _convertToCambodiaTime(String? time) {
    if (time == null || time.isEmpty) return '';

    try {
      // Parse the time (assuming format like "14:30" or "14:30:00")
      List<String> timeParts = time.split(':');
      if (timeParts.length < 2) return time;

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      // Convert to 12-hour format with AM/PM
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      // If parsing fails, return original time
      return time;
    }
  }

  Widget _buildScheduleSection(String title, List<Widget> rows) {
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // Horizontal scrollable table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: const BoxConstraints(minWidth: 600),
              child: Column(children: [_buildTableHeader(), ...rows]),
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
            width: 80,
            child: Text(
              'ប៉ុស្តិ',
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
              'ចន្ទ',
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
              'អង្គារ៍',
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
              'ពុធ',
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
              'ព្រហស្បតិ៍',
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
              'សុក្រ',
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
              'សៅរ៍',
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
              'អាទិត្យ',
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

  Widget _buildScheduleRow(
    String post,
    String monday,
    String tuesday,
    String wednesday,
    String thursday,
    String friday,
    String saturday,
    String sunday,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            child: Text(
              post,
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
              monday,
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
              tuesday,
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
              wednesday,
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
              thursday,
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
              friday,
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
              saturday,
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
              sunday,
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
}
