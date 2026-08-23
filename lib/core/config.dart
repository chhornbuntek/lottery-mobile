import 'receipt_image_template.dart';

/// Supabase: switch backend by changing [activeBranch] only
/// (`branch1`, `branch2`, `branch3`, or `branch4`).
class SupabaseConfig {
  /// Visible app build label for QA/client verification.
  static const String appBuildLabel = '1.0.1+7';

  /// Backend + in-app logo follow this value.
  /// Do not edit by hand when building APK — the command sets it:
  ///   dart run tool/prepare_branch.dart branch3
  /// That writes `activeBranch` (Supabase URL), logo, splash, and package id.
  static const String activeBranch = 'branch4';

  static String get supabaseUrl {
    switch (activeBranch) {
      case 'branch4':
        return _branch4Url;
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
      case 'branch4':
        return _branch4AnonKey;
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

  static const String _branch4Url = 'https://supabase-branch4.adminlot.site';
  static const String _branch4AnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzgyOTE2NjcwLCJleHAiOjE5NDA1OTY2NzB9.l4tZ5NzMIE0Y-UEBeff_e7KqaLaZeo5gJUlcWZzOBis';

  /// Home / launcher / receipt logo in `assets/`.
  static String get appLogoAsset {
    switch (activeBranch) {
      case 'branch1':
        return 'assets/logo_branch1.jpg';
      case 'branch3':
        return 'assets/logo_branch3.jpg';
      case 'branch4':
        return 'assets/logo_branch4.jpg';
      case 'branch2':
      default:
        return 'assets/logo2.png';
    }
  }

  /// Receipt header logo — same asset as the home logo.
  static String get receiptLogoAsset => appLogoAsset;

  /// branch1 / branch3 / branch4 → image header/footer receipt.
  /// branch2 → original code-designed receipt (logo + table + footer).
  static bool get usesImageReceiptTemplate => imageReceiptTemplate != null;

  static ImageReceiptTemplate? get imageReceiptTemplate =>
      ImageReceiptTemplate.forBranch(activeBranch);
}
