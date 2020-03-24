import 'dart:io';

import 'package:process_run/shell.dart';

var platforms = ['android', 'ios', 'linux', 'windows', 'web', 'macos'];
Future cleanUpProjects() async {
  for (var platform in platforms) {
    try {
      await Directory(platform).delete(recursive: true);
    } catch (_) {}
  }
}

Future main() async {
  var shell = Shell();
  await cleanUpProjects();
  await shell.run('flutter create -a java -i objc .');
}
