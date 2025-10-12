import 'package:supabase_flutter/supabase_flutter.dart';

class ResultApi {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch lottery results by date and time
  static Future<List<Map<String, dynamic>>> getResults({
    required DateTime date,
    String? lotteryTime,
  }) async {
    try {
      String formattedDate =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      var query = _supabase
          .from('results')
          .select('*')
          .eq('date', formattedDate);

      if (lotteryTime != null) {
        query = query.eq('time', lotteryTime);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching results: $e');
      return [];
    }
  }

  // Get available lottery times
  static Future<List<String>> getLotteryTimes() async {
    try {
      final response = await _supabase
          .from('lottery_times')
          .select('time_name')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return response.map((item) => item['time_name'] as String).toList();
    } catch (e) {
      print('Error fetching lottery times: $e');
      return ['អន្តរជាតិ 10:00', 'អន្តរជាតិ 14:00', 'អន្តរជាតិ 18:00'];
    }
  }

  // Get all channels
  static Future<List<Map<String, dynamic>>> getChannels() async {
    try {
      final response = await _supabase
          .from('channels')
          .select('channel_code, channel_name, sort_order')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching channels: $e');
      return [];
    }
  }
}
