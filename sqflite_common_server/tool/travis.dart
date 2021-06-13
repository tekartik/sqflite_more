import 'package:dev_test/package.dart';
import 'package:process_run/shell.dart';

Future main() async {
  await packageRunCi('.', options: PackageRunCiOptions(noTest: true));
  var shell = Shell();

  await shell.run('''
pub run test -p vm -j 1
  ''');
}
