import 'package:supabase_flutter/supabase_flutter.dart';

class ClosingTimeApi {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all closing times with their posts
  static Future<List<Map<String, dynamic>>> getAllClosingTimes() async {
    try {
      final response = await _supabase
          .from('closing_time')
          .select('''
            *,
            closing_time_posts (
              id,
              post_id,
              monday,
              tuesday,
              wednesday,
              thursday,
              friday,
              saturday,
              sunday,
              vip
            )
          ''')
          .order('id');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch closing times: $e');
    }
  }

  /// Get closing times by category
  static Future<List<Map<String, dynamic>>> getClosingTimesByCategory(
    String category,
  ) async {
    try {
      // First get lottery times by category
      final lotteryTimes = await _supabase
          .from('lottery_times')
          .select('time_name')
          .eq('time_category', category)
          .eq('is_active', true)
          .order('sort_order');

      if (lotteryTimes.isEmpty) {
        return [];
      }

      // Extract time names
      List<String> timeNames = lotteryTimes
          .map((e) => e['time_name'] as String)
          .toList();

      // Get closing times that match these lottery time names
      final response = await _supabase
          .from('closing_time')
          .select('''
            *,
            closing_time_posts (
              id,
              post_id,
              monday,
              tuesday,
              wednesday,
              thursday,
              friday,
              saturday,
              sunday,
              vip
            )
          ''')
          .inFilter('time_name', timeNames)
          .order('id');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch closing times by category: $e');
    }
  }

  /// Get closing time posts for a specific closing time
  static Future<List<Map<String, dynamic>>> getClosingTimePosts(
    int closingTimeId,
  ) async {
    try {
      final response = await _supabase
          .from('closing_time_posts')
          .select('*')
          .eq('closing_time_id', closingTimeId)
          .order('post_id');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch closing time posts: $e');
    }
  }
}
