import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/data.dart';

class DataService extends GetxController {
  // Observable variables
  final Rx<User?> _currentUser = Rx<User?>(null);
  final Rx<Map<String, dynamic>?> _userProfile = Rx<Map<String, dynamic>?>(
    null,
  );
  final RxString _userDisplayName = 'User'.obs;
  final RxString _userPhone = ''.obs;
  final RxBool _isLoading = false.obs;

  // Getters
  User? get currentUser => _currentUser.value;
  Map<String, dynamic>? get userProfile => _userProfile.value;
  String get userDisplayName => _userDisplayName.value;
  String get userPhone => _userPhone.value;
  bool get isLoading => _isLoading.value;
  bool get isAuthenticated => _currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  /// Initialize user data
  void _initializeData() async {
    _isLoading.value = true;

    // Set initial user
    _currentUser.value = DataApi.getCurrentUser();

    if (_currentUser.value != null) {
      await _loadUserData(_currentUser.value!.id);
    }

    _isLoading.value = false;

    // Listen to auth state changes
    DataApi.authStateChanges.listen((AuthState data) {
      _currentUser.value = data.session?.user;

      if (data.session?.user != null) {
        _loadUserData(data.session!.user.id);
      } else {
        _clearUserData();
      }
    });
  }

  /// Load user data from database
  Future<void> _loadUserData(String userId) async {
    try {
      _isLoading.value = true;

      final profile = await DataApi.getUserProfile(userId);
      _userProfile.value = profile;

      if (profile != null) {
        _userDisplayName.value = profile['full_name'] ?? 'User';
        _userPhone.value = profile['phone'] ?? '';
      }
    } catch (e) {
      print('Failed to load user data: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear user data
  void _clearUserData() {
    _userProfile.value = null;
    _userDisplayName.value = 'User';
    _userPhone.value = '';
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    if (_currentUser.value != null) {
      await _loadUserData(_currentUser.value!.id);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({String? fullName, String? phone}) async {
    if (_currentUser.value == null) return false;

    try {
      _isLoading.value = true;

      final updatedProfile = await DataApi.updateUserProfile(
        userId: _currentUser.value!.id,
        fullName: fullName,
        phone: phone,
      );

      _userProfile.value = updatedProfile;

      _userDisplayName.value = updatedProfile['full_name'] ?? 'User';
      _userPhone.value = updatedProfile['phone'] ?? '';

      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Update Error',
        'Failed to update profile: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get formatted phone number for display
  String get formattedPhone {
    if (_userPhone.value.isEmpty) return '';

    // Format phone number (e.g., 85587305120 -> 855 873 051 20)
    final phone = _userPhone.value;
    if (phone.length >= 9) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6, 9)}${phone.length > 9 ? ' ${phone.substring(9)}' : ''}';
    }
    return phone;
  }

  /// Get short phone number for display
  String get shortPhone {
    if (_userPhone.value.isEmpty) return '';

    final phone = _userPhone.value;

    // For phone numbers starting with 0, show first 6 digits
    if (phone.startsWith('0') && phone.length >= 6) {
      return phone.substring(0, 6);
    }

    // For phone numbers starting with 855, show middle 6 digits
    if (phone.startsWith('855') && phone.length >= 9) {
      return phone.substring(3, 9);
    }

    // For other cases, show first 6 digits if available
    if (phone.length >= 6) {
      return phone.substring(0, 6);
    }

    return phone;
  }
}
