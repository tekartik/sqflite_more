import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'sqflite_common_server',
  ]) {
    shell = shell.pushd(dir);
    await shell.run('''

pub get
dart tool/travis.dart

    ''');
    shell = shell.popd();
  }

  for (var dir in [
    'sqflite_porter',
    'sqflite_server',
    'sqflite_test',
    'sqflite_ffi_test',
    'sqflite_test_app',
    'sqflite_server_app',
    'alt/sqflite_github_test'
  ]) {
    shell = shell.pushd(dir);
    await shell.run('''

flutter packages get
dart tool/travis.dart

    ''');
    shell = shell.popd();
  }
}
