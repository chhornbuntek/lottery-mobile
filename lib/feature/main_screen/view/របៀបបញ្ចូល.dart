import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InputMethodScreen extends StatelessWidget {
  const InputMethodScreen({super.key});

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
          'របៀបបញ្ចូល',
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
            _buildInputMethodItem(
              'អូសគត់',
              'វាយបញ្ចូល 10-50',
              '= 10, 20, 30, 40, 50',
            ),
            _buildInputMethodItem(
              'អូស',
              'វាយបញ្ចូល 10>',
              '= 10, 11, 12, 13, 14,...,18,19',
            ),
            _buildInputMethodItem(
              'អូសកន្ទុយ',
              'វាយបញ្ចូល 25>',
              '= 25, 35, 45, 55, 65, 75, 85, 95',
            ),
            _buildInputMethodItem('ត្រលប់', 'វាយបញ្ចូល 25x', '= 25, 52'),
            _buildInputMethodItem(
              'អូសផែ',
              'វាយបញ្ចូល 11-44',
              '= 11, 22, 33, 44',
            ),
            _buildInputMethodItem(
              'អូសផែ',
              'វាយបញ្ចូល 000-333',
              '= 000, 111, 222, 333',
            ),
            _buildInputMethodItem(
              'អូសរៀង',
              'វាយបញ្ចូល 10-16',
              '= 10, 11, 12, 13, 14, 15, 16',
            ),
            _buildInputMethodItem(
              'អូសកណ្តាល',
              'វាយបញ្ចូល 153-183',
              '= 153, 163, 173, 183',
            ),
            _buildInputMethodItem(
              'អូសក្បាល',
              'វាយបញ្ចូល 120-620',
              '= 120, 220, 320, 420, 520, 620',
            ),
            _buildInputMethodItem(
              'អូសផែកន្ទុយ',
              'វាយបញ្ចូល 122-166',
              '= 122, 133, 144, 155, 166',
            ),
            _buildInputMethodItem(
              'អូសផែសងខាង',
              'វាយបញ្ចូល 121-525',
              '= 121, 222, 323, 424, 525',
            ),
            _buildInputMethodItem(
              'អូសផែក្បាល',
              'វាយបញ្ចូល 221-661',
              '= 221, 331, 441, 551, 661',
            ),
            _buildInputMethodItem(
              'អូសត្រលប់',
              'វាយបញ្ចូល 10-19x',
              '= 10, 01, 11, 12, 21,...,19, 91',
            ),
            _buildInputMethodItem(
              'អូសឆ្លង',
              'វាយបញ្ចូល 16>24',
              '= 16, 17, 18, 19, 20, 21, 22, 23, 24',
            ),
            _buildInputMethodItem(
              'អូសឆ្លង',
              'វាយបញ្ចូល 157>162',
              '= 157, 158, 159, 160, 161, 162',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputMethodItem(String title, String pattern, String example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: pattern,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      example,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
