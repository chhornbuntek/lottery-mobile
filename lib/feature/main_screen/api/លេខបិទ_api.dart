import 'package:supabase_flutter/supabase_flutter.dart';

class ClosingNumbersApi {
  static const String _tableName = 'closing_numbers';

  /// Get all closing numbers
  static Future<List<Map<String, dynamic>>> getClosingNumbers() async {
    try {
      print('🔍 ClosingNumbersApi: Fetching closing numbers...');

      final response = await Supabase.instance.client
          .from(_tableName)
          .select('*')
          .order('date', ascending: false)
          .order('time', ascending: false);

      print(
        '✅ ClosingNumbersApi: Successfully fetched ${response.length} closing numbers',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ ClosingNumbersApi Error: $e');
      rethrow;
    }
  }

  /// Get closing numbers by date
  static Future<List<Map<String, dynamic>>> getClosingNumbersByDate(
    String date,
  ) async {
    try {
      print('🔍 ClosingNumbersApi: Fetching closing numbers for date: $date');

      final response = await Supabase.instance.client
          .from(_tableName)
          .select('*')
          .eq('date', date)
          .order('time', ascending: false);

      print(
        '✅ ClosingNumbersApi: Successfully fetched ${response.length} closing numbers for $date',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ ClosingNumbersApi Error: $e');
      rethrow;
    }
  }

  /// Get closing numbers by time
  static Future<List<Map<String, dynamic>>> getClosingNumbersByTime(
    String time,
  ) async {
    try {
      print('🔍 ClosingNumbersApi: Fetching closing numbers for time: $time');

      final response = await Supabase.instance.client
          .from(_tableName)
          .select('*')
          .eq('time', time)
          .order('date', ascending: false);

      print(
        '✅ ClosingNumbersApi: Successfully fetched ${response.length} closing numbers for $time',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ ClosingNumbersApi Error: $e');
      rethrow;
    }
  }

  /// Get recent closing numbers (last 7 days)
  static Future<List<Map<String, dynamic>>> getRecentClosingNumbers() async {
    try {
      print('🔍 ClosingNumbersApi: Fetching recent closing numbers...');

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final response = await Supabase.instance.client
          .from(_tableName)
          .select('*')
          .gte('date', sevenDaysAgo.toIso8601String().split('T')[0])
          .order('date', ascending: false)
          .order('time', ascending: false);

      print(
        '✅ ClosingNumbersApi: Successfully fetched ${response.length} recent closing numbers',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ ClosingNumbersApi Error: $e');
      rethrow;
    }
  }
}
