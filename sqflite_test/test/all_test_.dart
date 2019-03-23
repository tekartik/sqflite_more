import 'package:sqflite_test/sqflite_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exception_test.dart' as exception_test;
import 'exp_test.dart' as exp_test;
import 'open_test.dart' as open_test;
import 'raw_test.dart' as raw_test;
import 'statement_test.dart' as statement_test;
import 'type_test.dart' as type_test;

Future main() {
  return testMain(run);
}

void run(SqfliteServerTestContext context) {
  group('local', () {
    type_test.run(context);
    statement_test.run(context);
    raw_test.run(context);
    exp_test.run(context);
    open_test.run(context);
    exception_test.run(context);
  });
}
