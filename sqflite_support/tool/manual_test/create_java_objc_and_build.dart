import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:sqflite_support/sqflite_support.dart';

import 'create_and_build.dart';

Future createProject(String dir) async {
  await createEmptyDir(dir);
  await initFlutter();
  var shell = Shell(workingDirectory: dir);
  await shell.run('flutter create -a java -i objc .');
}

Future main() async {
  var dir = join('.dart_tool', 'sqflite', 'java_objc_project');
  await createProject(dir);
  await addSqfliteAndBuild(dir);
}
