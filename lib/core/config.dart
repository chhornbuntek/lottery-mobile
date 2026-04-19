/// Supabase: switch backend by changing [activeBranch] only (`branch1` or `branch2`).
class SupabaseConfig {
  /// Set to `branch1` or `branch2` — no build flags needed.
  static const String activeBranch = 'branch2';

  static String get supabaseUrl {
    switch (activeBranch) {
      case 'branch2':
        return _branch2Url;
      case 'branch1':
      default:
        return _branch1Url;
    }
  }

  static String get supabaseAnonKey {
    switch (activeBranch) {
      case 'branch2':
        return _branch2AnonKey;
      case 'branch1':
      default:
        return _branch1AnonKey;
    }
  }

  static const String _branch1Url = 'https://supabase.adminlot.site';
  static const String _branch1AnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzY5NzA2MDAwLCJleHAiOjE5Mjc0NzI0MDB9.EtdMV2KcCgWH8w5SHCrDHbc1oJvt6qtubZRP13coKfM';

  static const String _branch2Url = 'https://supabase-branch2.adminlot.site';
  static const String _branch2AnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc2NTMxNjAwLCJleHAiOjE5MzQyOTgwMDB9.26FXu01ohv6gqvLMBI0_t4ravrMPPjpEzzYsjEsMqNw';
}
