import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:sqflite_test/sqflite_test.dart';

Future main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  return testMain(run);
}

void run(SqfliteTestContext context) {
  group('common', () {
    all.run(context);
  });
}
