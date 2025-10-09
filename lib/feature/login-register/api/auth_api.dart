import 'package:supabase_flutter/supabase_flutter.dart';

class AuthApi {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Register a new user with phone number as email
  static Future<AuthResponse> register({
    required String phone,
    required String password,
    required String fullName,
  }) async {
    try {
      // Format phone number as email for Supabase auth
      final email = _formatPhoneAsEmail(phone);

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      return response;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Login user with phone number as email
  static Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    try {
      // Format phone number as email for Supabase auth
      final email = _formatPhoneAsEmail(phone);

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Format phone number as email address for Supabase auth
  static String _formatPhoneAsEmail(String phone) {
    // Remove any non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Format as email: phone@phone.com
    return '$cleanPhone@phone.com';
  }

  /// Logout current user
  static Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Get user profile from database
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profile')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;

      final response = await _client
          .from('profile')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  /// Get authentication stream
  static Stream<AuthState> get authStateChanges {
    return _client.auth.onAuthStateChange;
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// Update password
  static Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      throw Exception('Password update failed: ${e.toString()}');
    }
  }
}
