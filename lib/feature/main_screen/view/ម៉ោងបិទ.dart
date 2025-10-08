import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClosingTimeScreen extends StatelessWidget {
  const ClosingTimeScreen({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildScheduleSection('ខ្មែរVIP 10:35AM', [
              _buildScheduleRow('A', '10:33', '10:33', '10:33'),
              _buildScheduleRow('B', '10:33', '10:33', '10:33'),
              _buildScheduleRow('C', '10:33', '10:33', '10:33'),
              _buildScheduleRow('D', '10:33', '10:33', '10:33'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('ខ្មែរVIP 1:00PM', [
              _buildScheduleRow('A', '12:58', '12:58', '12:58'),
              _buildScheduleRow('B', '12:58', '12:58', '12:58'),
              _buildScheduleRow('C', '12:58', '12:58', '12:58'),
              _buildScheduleRow('D', '12:58', '12:58', '12:58'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('យួន 1:30PM', [
              _buildScheduleRow('A', '13:14', '13:14', '13:15'),
              _buildScheduleRow('B', '13:25', '13:25', '13:25'),
              _buildScheduleRow('C', '13:25', '13:25', '13:25'),
              _buildScheduleRow('D', '13:25', '13:25', '13:25'),
              _buildScheduleRow('Lo', '13:05', '13:08', '13:05'),
              _buildScheduleRow('F', '13:14', '13:14', '13:15'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('ខ្មែរVIP 3:45PM', [
              _buildScheduleRow('A', '15:43', '15:43', '15:43'),
              _buildScheduleRow('B', '15:43', '15:43', '15:43'),
              _buildScheduleRow('C', '15:43', '15:43', '15:43'),
              _buildScheduleRow('D', '15:43', '15:43', '15:43'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('យួន 4:30PM', [
              _buildScheduleRow('A', '16:12', '16:12', '16:12'),
              _buildScheduleRow('B', '16:25', '16:25', '16:25'),
              _buildScheduleRow('C', '16:25', '16:25', '16:25'),
              _buildScheduleRow('D', '16:25', '16:25', '16:25'),
              _buildScheduleRow('F', '16:12', '16:12', '16:12'),
              _buildScheduleRow('I', '16:10', '16:10', '16:10'),
              _buildScheduleRow('N', '16:20', '16:20', '16:20'),
              _buildScheduleRow('Lo', '16:05', '16:05', '16:05'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('ខ្មែរVIP 6:00PM', [
              _buildScheduleRow('A', '17:58', '17:58', '17:58'),
              _buildScheduleRow('B', '17:58', '17:58', '17:58'),
              _buildScheduleRow('C', '17:58', '17:58', '17:58'),
              _buildScheduleRow('D', '17:58', '17:58', '17:58'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('យួន 6:30PM', [
              _buildScheduleRow('A', '18:14', '18:14', '18:14'),
              _buildScheduleRow('B', '18:23', '18:23', '18:23'),
              _buildScheduleRow('C', '18:23', '18:23', '18:23'),
              _buildScheduleRow('D', '18:23', '18:23', '18:23'),
              _buildScheduleRow('Lo', '18:05', '18:05', '18:05'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('ខ្មែរVIP 7:45PM', [
              _buildScheduleRow('A', '19:43', '19:43', '19:43'),
              _buildScheduleRow('B', '19:43', '19:43', '19:43'),
              _buildScheduleRow('C', '19:43', '19:43', '19:43'),
              _buildScheduleRow('D', '19:43', '19:43', '19:43'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('ថៃ', [
              _buildScheduleRow('ថៃ', '15:20', '15:20', '15:20'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('យួន 7:30PM', [
              _buildScheduleRow('A', '19:30', '19:30', '19:30'),
              _buildScheduleRow('B', '19:35', '19:35', '19:35'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('អន្តរជាតិ 8:00am', [
              _buildScheduleRow('A', '07:58', '07:58', '07:58'),
              _buildScheduleRow('B', '07:58', '07:58', '07:58'),
              _buildScheduleRow('C', '07:58', '07:58', '07:58'),
              _buildScheduleRow('D', '07:58', '07:58', '07:58'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('អន្តរជាតិ 10:00', [
              _buildScheduleRow('A', '09:58', '09:58', '09:58'),
              _buildScheduleRow('B', '09:58', '09:58', '09:58'),
              _buildScheduleRow('C', '09:58', '09:58', '09:58'),
              _buildScheduleRow('D', '09:58', '09:58', '09:58'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('អន្តរជាតិ 12:00', [
              _buildScheduleRow('A', '11:59', '11:59', '11:59'),
              _buildScheduleRow('B', '11:58', '11:58', '11:58'),
              _buildScheduleRow('C', '11:58', '11:58', '11:58'),
              _buildScheduleRow('D', '11:58', '11:58', '11:58'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('អន្តរជាតិ 2:00pm', [
              _buildScheduleRow('A', '13:58', '13:58', '13:58'),
              _buildScheduleRow('B', '13:58', '13:58', '13:58'),
              _buildScheduleRow('C', '13:58', '13:58', '13:58'),
              _buildScheduleRow('D', '13:58', '13:58', '13:58'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('អន្តរជាតិ 4:00pm', [
              _buildScheduleRow('A', '15:58', '15:58', '15:58'),
              _buildScheduleRow('B', '15:58', '15:58', '15:58'),
              _buildScheduleRow('C', '15:58', '15:58', '15:58'),
              _buildScheduleRow('D', '15:58', '15:58', '15:58'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('អន្តរជាតិ 6:00pm', [
              _buildScheduleRow('A', '17:58', '17:58', '17:58'),
              _buildScheduleRow('B', '17:58', '17:58', '17:58'),
              _buildScheduleRow('C', '17:58', '17:58', '17:58'),
              _buildScheduleRow('D', '17:58', '17:58', '17:58'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('ខ្មែរVIP 8:45AM', [
              _buildScheduleRow('A', '08:44', '08:44', '08:44'),
              _buildScheduleRow('B', '08:44', '08:44', '08:44'),
              _buildScheduleRow('C', '08:44', '08:44', '08:44'),
              _buildScheduleRow('D', '08:44', '08:44', '08:44'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('យួន 10:30AM', [
              _buildScheduleRow('A', '10:25', '10:25', '10:25'),
              _buildScheduleRow('B', '10:39', '10:39', '10:39'),
              _buildScheduleRow('C', '10:39', '10:39', '10:39'),
              _buildScheduleRow('D', '10:39', '10:39', '10:39'),
              _buildScheduleRow('Lo', '10:25', '10:25', '10:25'),
              _buildScheduleRow('F', '10:25', '10:25', '10:25'),
            ]),
            const SizedBox(height: 20),
            _buildScheduleSection('អន្តរជាតិ 2:00pm', [
              _buildScheduleRow('A', '13:58', '13:58', '13:58'),
              _buildScheduleRow('B', '13:58', '13:58', '13:58'),
              _buildScheduleRow('C', '13:58', '13:58', '13:58'),
              _buildScheduleRow('D', '13:58', '13:58', '13:58'),
            ]),
          ],
        ),
      ),
    );
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
          _buildTableHeader(),
          ...rows,
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
          Expanded(
            flex: 1,
            child: Text(
              'ប៉ុស្តិ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 1,
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
          Expanded(
            flex: 1,
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
          Expanded(
            flex: 1,
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
        ],
      ),
    );
  }

  Widget _buildScheduleRow(
    String post,
    String monday,
    String tuesday,
    String wednesday,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              post,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 1,
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
          Expanded(
            flex: 1,
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
          Expanded(
            flex: 1,
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
        ],
      ),
    );
  }
}
