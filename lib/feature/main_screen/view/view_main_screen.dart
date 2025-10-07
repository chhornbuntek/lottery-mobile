import 'package:flutter/material.dart';
import 'ក្បាលបញ្ជី.dart';
import 'បញ្ជី.dart';
import 'ភ្នាល់.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // Handle menu button press
          },
        ),
        title: const Text(
          '012333444',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildLogoSection(),

              const SizedBox(height: 30),

              _buildInfoLine(),

              const SizedBox(height: 40),

              _buildButtonGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: Colors.grey, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit, color: Colors.grey, size: 40),
          const SizedBox(height: 10),
          const Text(
            'ទទួល',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'កត់ឆ្នោត',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'LOTTERY-GROUP',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.refresh, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        const Text(
          'លេខដែលបានបិទ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.0,
      children: [
        _buildGridButton(context, Icons.description, 'សរុប'),
        _buildGridButton(context, Icons.add, 'ភ្នាល់'),
        _buildGridButton(context, Icons.attach_money, 'កម្រៃ'),
        _buildGridButton(context, Icons.list, 'បញ្ជី'),
        _buildGridButton(context, Icons.book, 'ក្បាលបញ្ជី'),
        _buildGridButton(context, Icons.exit_to_app, 'លទ្ធផល'),
        _buildGridButton(context, Icons.delete, 'ស្មើរសុំលុប'),
        _buildGridButton(context, Icons.abc, 'របៀបបញ្ចូល'),
        _buildGridButton(context, Icons.access_time, 'ម៉ោងបិទ'),
      ],
    );
  }

  Widget _buildGridButton(BuildContext context, IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (label == 'ក្បាលបញ្ជី') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LedgerScreen()),
              );
            } else if (label == 'បញ្ជី') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListScreen()),
              );
            } else if (label == 'ភ្នាល់') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BettingScreen()),
              );
            } else {
              debugPrint('Pressed: $label');
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
