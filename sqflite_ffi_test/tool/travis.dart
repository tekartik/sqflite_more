import 'dart:io';

import 'package:process_run/shell.dart';
import 'linux_setup.dart' as linux_setup;

bool get runningOnTravis => Platform.environment['TRAVIS'] == 'true';
Future main() async {
  var shell = Shell();

  if (runningOnTravis) {
    await linux_setup.main();
  }

  // await linux_setup.main();
  await shell.run('''

flutter analyze --no-current-package lib test
flutter test
  ''');
}
