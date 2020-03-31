import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_test_app/main.dart';

Future main() async {
  await sqfliteTestAppInit(sqfliteLogLevel: sqfliteLogLevelVerbose);
}
