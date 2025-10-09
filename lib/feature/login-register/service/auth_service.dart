import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../api/auth_api.dart';

class AuthService extends GetxController {
  // Observable variables
  final Rx<User?> _currentUser = Rx<User?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final Rx<Map<String, dynamic>?> _userProfile = Rx<Map<String, dynamic>?>(
    null,
  );

  // Getters
  User? get currentUser => _currentUser.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  Map<String, dynamic>? get userProfile => _userProfile.value;
  bool get isAuthenticated => _currentUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  /// Initialize authentication state
  void _initializeAuth() {
    // Set initial user
    _currentUser.value = AuthApi.getCurrentUser();

    // Listen to auth state changes
    AuthApi.authStateChanges.listen((AuthState data) {
      _currentUser.value = data.session?.user;

      if (data.session?.user != null) {
        _loadUserProfile(data.session!.user.id);
      } else {
        _userProfile.value = null;
      }
    });
  }

  /// Register new user
  Future<bool> register({
    required String phone,
    required String password,
    required String fullName,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final response = await AuthApi.register(
        phone: phone,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        _currentUser.value = response.user;
        await _loadUserProfile(response.user!.id);

        Get.snackbar(
          'Success',
          'Registration successful!',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _errorMessage.value = 'Registration failed. Please try again.';
        return false;
      }
    } catch (e) {
      _errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Registration Error',
        _errorMessage.value,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Login user
  Future<bool> login({required String phone, required String password}) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final response = await AuthApi.login(phone: phone, password: password);

      if (response.user != null) {
        _currentUser.value = response.user;
        await _loadUserProfile(response.user!.id);

        Get.snackbar(
          'Success',
          'Login successful!',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );

        return true;
      } else {
        _errorMessage.value = 'Login failed. Please check your credentials.';
        return false;
      }
    } catch (e) {
      _errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Login Error',
        _errorMessage.value,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _isLoading.value = true;

      await AuthApi.logout();
      _currentUser.value = null;
      _userProfile.value = null;

      Get.snackbar(
        'Success',
        'Logged out successfully',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Logout Error',
        'Failed to logout: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      final profile = await AuthApi.getUserProfile(userId);
      _userProfile.value = profile;
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }

  /// Update user profile
  Future<bool> updateProfile({String? fullName, String? phone}) async {
    if (_currentUser.value == null) return false;

    try {
      _isLoading.value = true;

      final updatedProfile = await AuthApi.updateUserProfile(
        userId: _currentUser.value!.id,
        fullName: fullName,
        phone: phone,
      );

      _userProfile.value = updatedProfile;

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

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading.value = true;

      await AuthApi.resetPassword(email);

      Get.snackbar(
        'Success',
        'Password reset email sent!',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Reset Error',
        'Failed to send reset email: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      _isLoading.value = true;

      await AuthApi.updatePassword(newPassword);

      Get.snackbar(
        'Success',
        'Password updated successfully!',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Update Error',
        'Failed to update password: ${e.toString()}',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  /// Get user display name
  String get userDisplayName {
    if (_userProfile.value != null) {
      return _userProfile.value!['full_name'] ?? 'User';
    }
    return _currentUser.value?.email ?? 'User';
  }

  /// Get user phone
  String get userPhone {
    if (_userProfile.value != null) {
      return _userProfile.value!['phone'] ?? '';
    }
    return '';
  }
}
