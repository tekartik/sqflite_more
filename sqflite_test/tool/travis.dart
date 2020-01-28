import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''

flutter format --set-exit-if-changed lib test tool
flutter analyze --no-current-package lib test tool
flutter test
  ''');
}
