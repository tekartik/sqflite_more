// The shared sqflite_common_test suite on a device (Android, Linux) with
// sqflite_common_ffi only. Run it with tool/sqflite_suite_run.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  var context = SqfliteLocalTestContext(databaseFactory: databaseFactoryFfi);
  setUpAll(() async {
    // The ffi default (.dart_tool in the current directory) is not writable
    // on Android.
    var dir = await getApplicationSupportDirectory();
    await databaseFactoryFfi.setDatabasesPath(join(dir.path, 'databases'));
  });
  all.run(context);
}
