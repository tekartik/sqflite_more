import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'sqflite_common_server',
    'sqflite_common_test_app',
    'sqflite_porter',
    'sqflite_server',
    'sqflite_test',
    'sqflite_ffi_test',
    'sqflite_test_app',
    'sqflite_server_app',
    'alt/sqflite_github_test'
  ]) {
    await packageRunCi(join('..', dir));
  }
  await packageRunCi('.');
}
