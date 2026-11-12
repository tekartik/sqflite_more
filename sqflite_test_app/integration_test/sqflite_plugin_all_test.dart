// The shared sqflite_common_test suite on a device with the sqflite plugin
// (Android, iOS, macOS). Run it with tool/sqflite_suite_run.dart.
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';

/// The plugin context, as the sqflite repository integration test.
class SqflitePluginTestContext extends SqfliteLocalTestContext {
  /// The plugin factory.
  SqflitePluginTestContext() : super(databaseFactory: databaseFactory);

  @override
  bool get isPlugin => true;

  @override
  bool get supportsRecoveredInTransaction => true;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  all.run(SqflitePluginTestContext());
}
