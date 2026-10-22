import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'sqflite_common_server',
    'sqflite_common_test_app',
    'sqflite_common_porter',
    'sqflite_porter',
    'sqflite_server',
    'sqflite_test',
    'sqflite_test_app',
    'sqflite_server_app',
    // exp1: tests in exp1_common and exp1_support, format and analyze for
    // the apps (the scenario tool needs devices, run it manually)
    'exp1/exp1_common',
    'exp1/exp1_sqflite',
    'exp1/exp1_sqflite_ffi',
    'exp1/exp1_web',
    'exp1/exp1_app',
    'exp1/exp1_support',
  ]) {
    await packageRunCi(join('..', dir));
  }
  await packageRunCi('.');
}
