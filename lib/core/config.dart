/// Supabase: switch backend by changing [activeBranch] only
/// (`branch1`, `branch2`, or `branch3`).
class SupabaseConfig {
  /// Set to `branch1`, `branch2`, or `branch3` — no build flags needed.
  static const String activeBranch = 'branch3';

  static String get supabaseUrl {
    switch (activeBranch) {
      case 'branch3':
        return _branch3Url;
      case 'branch2':
        return _branch2Url;
      case 'branch1':
      default:
        return _branch1Url;
    }
  }

  static String get supabaseAnonKey {
    switch (activeBranch) {
      case 'branch3':
        return _branch3AnonKey;
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

  static const String _branch3Url = 'https://supabase-branch3.adminlot.site';
  static const String _branch3AnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc3Mzk1NjAwLCJleHAiOjE5MzUxNjIwMDB9.fnp-WwRsGfpFpbLPjqkjXLFEsO4pLehx1isgjP6vjyc';

  /// Receipt header logo in `assets/` (add the file for branch3 — e.g. `logo-branch3.jpg`).
  static String get receiptLogoAsset {
    switch (activeBranch) {
      case 'branch3':
        return 'assets/logo-branch3.jpg';
      case 'branch2':
      case 'branch1':
      default:
        return 'assets/logo2.png';
    }
  }
}
