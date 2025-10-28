import 'package:supabase_flutter/supabase_flutter.dart';

class AuthApi {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Register a new user with phone number as email
  static Future<AuthResponse> register({
    required String phone,
    required String password,
    required String fullName,
    String? adminId,
  }) async {
    try {
      // Format phone number as email for Supabase auth
      final email = _formatPhoneAsEmail(phone);

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phone},
      );

      // If user was created successfully and adminId is provided, update profile
      if (response.user != null && adminId != null) {
        await _client
            .from('profile')
            .update({'admin_id': adminId})
            .eq('id', response.user!.id);
      }

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

  /// Get all admin users for dropdown selection
  static Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      // Use Edge Function for better security and to avoid RLS issues
      final response = await _client.functions.invoke('get-admin-users');

      if (response.data != null && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(
          response.data['adminUsers'] ?? [],
        );
      } else {
        throw Exception('Failed to fetch admin users from Edge Function');
      }
    } catch (e) {
      // Fallback to direct database query if Edge Function fails
      try {
        final response = await _client
            .from('profile')
            .select('id, full_name, phone')
            .eq('role', 'admin')
            .order('full_name');

        return List<Map<String, dynamic>>.from(response);
      } catch (fallbackError) {
        throw Exception('Failed to fetch admin users: ${e.toString()}');
      }
    }
  }

  /// Get current user's admin_id from profile
  static Future<String?> getCurrentUserAdminId() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('profile')
          .select('admin_id')
          .eq('id', user.id)
          .single();

      return response['admin_id'] as String?;
    } catch (e) {
      print('Failed to get user admin_id: $e');
      return null;
    }
  }
}
