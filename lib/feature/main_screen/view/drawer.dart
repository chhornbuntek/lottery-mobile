import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'របៀបបញ្ចូល.dart';
import 'ម៉ោងបិទ.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFF2C5F5F),
        child: Column(
          children: [
            _buildHeader(),
            _buildMenuItems(),
            const Spacer(),
            _buildVersionInfo(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildLogo(),
          const SizedBox(height: 20),
          _buildPhoneNumber(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit, color: Colors.amber, size: 30),
          const SizedBox(height: 8),
          Text(
            'ទទួល',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'កត់ឆ្នោត',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'LOTTERY-GROUP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumber() {
    return Text(
      '016328315',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMenuItems() {
    return Expanded(
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.abc,
            title: 'របៀបបញ្ចូល',
            onTap: () {
              Get.back();
              Get.to(() => const InputMethodScreen());
            },
          ),
          _buildMenuItem(
            icon: Icons.access_time,
            title: 'ម៉ោងបិទ',
            onTap: () {
              Get.back();
              Get.to(() => const ClosingTimeScreen());
            },
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'ការកំណត់',
            onTap: () {
              Get.back();
            },
          ),
          _buildMenuItem(
            icon: Icons.exit_to_app,
            title: 'ចាកចេញ',
            onTap: () {
              Get.back();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.amber, size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: Colors.transparent,
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'ជំនាន់ 2.9',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
