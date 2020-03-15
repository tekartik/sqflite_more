import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_test/sqflite_test.dart';

import 'open_flutter_test.dart' as open_flutter_test;

Future main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  return testMain(run);
}

void run(SqfliteTestContext context) {
  group('local', () {
    open_flutter_test.run(context);
  });
}
