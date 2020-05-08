import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:sqflite_support/sqflite_support.dart';

Future createEmptyDir(String dir) async {
  try {
    await Directory(dir).delete(recursive: true);
  } catch (_) {}
  await Directory(dir).create(recursive: true);
}

Future addSqfliteAndBuild(String dir) async {
  var shell = Shell(workingDirectory: dir);
  // Add sqflite dependencies
  var pubspecFile = File(join(dir, 'pubspec.yaml'));

  var content = await pubspecFile.readAsString();
  content = pubspecStringAddSqflite(content);
  // print(content);
  await pubspecFile.writeAsString(content);

  if (Platform.isMacOS) {
    // Build for iOS
    await shell.run('flutter build ios');
    if (supportsMacOS) {
      // Build for MacOS
      await shell.run('''
      flutter build macos
      ''');
    }
  }
  // Build for Android!
  await shell.run('flutter build apk');

  if (supportsLinux) {
    // Build for Linux
    await shell.run('flutter build linux');
  }
}

Future createProject(String dir) async {
  await createEmptyDir(dir);
  await initFlutter();
  var shell = Shell(workingDirectory: dir);
  await shell.run('flutter create .');
}

Future main() async {
  var dir = join('.dart_tool', 'sqflite', 'project');
  await createProject(dir);
  await addSqfliteAndBuild(dir);
}
