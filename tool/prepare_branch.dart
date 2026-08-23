import 'dart:io';

/// Reads [SupabaseConfig.activeBranch] and applies that branch's logo,
/// splash color, Android applicationId, and iOS bundle id.
///
/// Usage:
///   dart run tool/prepare_branch.dart
///   dart run tool/prepare_branch.dart branch3
void main(List<String> args) {
  final root = Directory.current;
  final configFile = File('${root.path}/lib/core/config.dart');
  if (!configFile.existsSync()) {
    stderr.writeln('Run this from the project root.');
    exit(1);
  }

  var branch = args.isNotEmpty ? args.first.trim() : _readActiveBranch(configFile);
  if (!_branding.containsKey(branch)) {
    stderr.writeln('Unknown branch "$branch". Use: ${_branding.keys.join(', ')}');
    exit(1);
  }

  if (args.isNotEmpty) {
    _setActiveBranch(configFile, branch);
  }

  final brand = _branding[branch]!;
  stdout.writeln('Preparing $branch');
  stdout.writeln('  backend: ${_backendUrl(configFile)}');
  stdout.writeln('  logo:    ${brand.logo}');
  stdout.writeln('  package: ${brand.applicationId}');

  _writePubspec(File('${root.path}/pubspec.yaml'), brand);
  _writeBranchProperties(
    File('${root.path}/android/app/branch.properties'),
    branch,
    brand.applicationId,
  );
  _writeIosBundleId(
    File('${root.path}/ios/Runner.xcodeproj/project.pbxproj'),
    brand.applicationId,
  );
  _writeMacosBundleId(
    File('${root.path}/macos/Runner/Configs/AppInfo.xcconfig'),
    brand.applicationId,
  );
  _writeGoogleServices(
    File('${root.path}/google-services.json'),
    brand.applicationId,
  );
  _writeFirebaseIosBundle(
    File('${root.path}/lib/core/firebase_option.dart'),
    brand.applicationId,
  );

  _run('dart', ['run', 'flutter_launcher_icons']);
  _run('dart', ['run', 'flutter_native_splash:create']);

  stdout.writeln('Done. Build with: flutter build apk --release');
}

class _Brand {
  const _Brand({
    required this.logo,
    required this.color,
    required this.applicationId,
  });

  final String logo;
  final String color;
  final String applicationId;
}

const _branding = <String, _Brand>{
  'branch1': _Brand(
    logo: 'assets/logo_branch1.jpg',
    color: '#0B2A5C',
    applicationId: 'com.lottery.branch1',
  ),
  'branch2': _Brand(
    logo: 'assets/logo2.png',
    color: '#2C5F5F',
    applicationId: 'com.lottery.branch2',
  ),
  'branch3': _Brand(
    logo: 'assets/logo_branch3.jpg',
    color: '#FFFFFF',
    applicationId: 'com.lottery.branch3',
  ),
  'branch4': _Brand(
    logo: 'assets/logo_branch4.jpg',
    color: '#8B1A1A',
    applicationId: 'com.lottery.branch4',
  ),
};

String _readActiveBranch(File configFile) {
  final match = RegExp(
    r"static const String activeBranch = '([^']+)';",
  ).firstMatch(configFile.readAsStringSync());
  if (match == null) {
    stderr.writeln('Could not read activeBranch from lib/core/config.dart');
    exit(1);
  }
  return match.group(1)!;
}

void _setActiveBranch(File configFile, String branch) {
  final updated = configFile.readAsStringSync().replaceFirst(
    RegExp(r"static const String activeBranch = '[^']+';"),
    "static const String activeBranch = '$branch';",
  );
  configFile.writeAsStringSync(updated);
  stdout.writeln('Set activeBranch = $branch (backend URL follows this)');
}

String _backendUrl(File configFile) {
  final text = configFile.readAsStringSync();
  final branch = _readActiveBranch(configFile);
  final key = switch (branch) {
    'branch4' => '_branch4Url',
    'branch3' => '_branch3Url',
    'branch2' => '_branch2Url',
    _ => '_branch1Url',
  };
  final match = RegExp("static const String $key = '([^']+)';").firstMatch(text);
  return match?.group(1) ?? '(unknown)';
}

void _writePubspec(File file, _Brand brand) {
  var text = file.readAsStringSync();
  final start = text.indexOf('# App Icon Configuration');
  if (start < 0) {
    stderr.writeln('Could not find launcher icon block in pubspec.yaml');
    exit(1);
  }
  file.writeAsStringSync('${text.substring(0, start)}${_pubspecBlock(brand)}');
}

String _pubspecBlock(_Brand brand) => '''
# App Icon Configuration
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "${brand.logo}"
  remove_alpha_ios: true
  min_sdk_android: 21 # android min sdk min:16, default 21
  web:
    generate: true
    image_path: "${brand.logo}"
    background_color: "${brand.color}"
    theme_color: "${brand.color}"
  windows:
    generate: true
    image_path: "${brand.logo}"
    icon_size: 48 # min:48, max:256, default 48
  macos:
    generate: true
    image_path: "${brand.logo}"

# Splash Screen Configuration
flutter_native_splash:
  color: "${brand.color}"
  image: ${brand.logo}
  android: true
  ios: true
  web: true
  android_12:
    color: "${brand.color}"
    image: ${brand.logo}
''';

void _writeBranchProperties(File file, String branch, String id) {
  file.writeAsStringSync('branch=$branch\napplicationId=$id\n');
}

void _writeMacosBundleId(File file, String id) {
  if (!file.existsSync()) return;
  file.writeAsStringSync(
    file.readAsStringSync().replaceFirst(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = com\.lottery\.[^\s]+'),
      'PRODUCT_BUNDLE_IDENTIFIER = $id',
    ),
  );
}

void _writeIosBundleId(File file, String id) {
  if (!file.existsSync()) return;
  file.writeAsStringSync(
    file.readAsStringSync().replaceAll(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = com\.lottery\.[^;]+;'),
      'PRODUCT_BUNDLE_IDENTIFIER = $id;',
    ),
  );
}

void _writeGoogleServices(File file, String id) {
  if (!file.existsSync()) return;
  file.writeAsStringSync(
    file.readAsStringSync().replaceFirst(
      RegExp(r'"package_name": "[^"]+"'),
      '"package_name": "$id"',
    ),
  );
}

void _writeFirebaseIosBundle(File file, String id) {
  if (!file.existsSync()) return;
  file.writeAsStringSync(
    file.readAsStringSync().replaceAll(
      RegExp(r"iosBundleId: 'com\.lottery\.[^']+'"),
      "iosBundleId: '$id'",
    ),
  );
}

void _run(String executable, List<String> args) {
  stdout.writeln('> $executable ${args.join(' ')}');
  final result = Process.runSync(
    executable,
    args,
    runInShell: true,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}
