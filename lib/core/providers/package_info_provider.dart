import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provider for PackageInfo instance (to be initialized in main.dart)
final packageInfoProvider = Provider<PackageInfo>((ref) {
  throw UnimplementedError(
    'PackageInfo has not been initialized. Make sure to override packageInfoProvider inside main.dart',
  );
});
