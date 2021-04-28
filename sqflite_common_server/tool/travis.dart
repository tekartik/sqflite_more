import 'package:process_run/shell.dart';
import 'package:dev_test/package.dart';

Future main() async {
  await packageRunCi('.');
  var shell = Shell();

  await shell.run('''

dartanalyzer --fatal-warnings --fatal-infos .
dartfmt -n --set-exit-if-changed .

pub run test -p vm -j 1

  ''');
}
