import 'package:supabase_flutter/supabase_flutter.dart';

class DataApi {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Get user profile data
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

  /// Get current user data
  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Get user display name
  static Future<String> getUserDisplayName(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null && profile['full_name'] != null) {
        return profile['full_name'];
      }
      return 'User';
    } catch (e) {
      return 'User';
    }
  }

  /// Get user phone number
  static Future<String> getUserPhone(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null && profile['phone'] != null) {
        return profile['phone'];
      }
      return '';
    } catch (e) {
      return '';
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
}
