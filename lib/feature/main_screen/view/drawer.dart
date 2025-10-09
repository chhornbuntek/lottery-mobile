import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/data_service.dart';
import '../../login-register/service/auth_service.dart';
import '../../login-register/view/login_screen.dart';
import 'របៀបបញ្ចូល.dart';
import 'ម៉ោងបិទ.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFF2C5F5F),
        child: SafeArea(
          child: Column(
            children: [
              Flexible(flex: 2, child: _buildHeader()),
              Flexible(flex: 3, child: _buildMenuItems()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          _buildLogo(),
          const SizedBox(height: 16),
          _buildPhoneNumber(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit, color: Colors.amber, size: 24),
          const SizedBox(height: 6),
          Text(
            'ទទួល',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'កត់ឆ្នោត',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'LOTTERY-GROUP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumber() {
    return Obx(() {
      final dataService = Get.find<DataService>();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dataService.userDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            dataService.formattedPhone.isNotEmpty
                ? dataService.formattedPhone
                : 'No Phone',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      );
    });
  }

  Widget _buildMenuItems() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            onTap: () async {
              Get.back();
              final authService = Get.find<AuthService>();
              await authService.logout();
              // Navigation will be handled by AuthWrapper automatically
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: Colors.amber, size: 20),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: Colors.transparent,
        dense: true,
        minLeadingWidth: 32,
      ),
    );
  }
}
