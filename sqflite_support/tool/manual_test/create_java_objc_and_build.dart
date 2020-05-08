import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

import 'create_and_build.dart';

Future main() async {
  var dir = join('.dart_tool', 'sqflite', 'java_objc_project');
  await createEmptyDir(dir);

  var shell = Shell(workingDirectory: dir);

  await shell.run('flutter create -a java -i objc .');

  await addSqfliteAndBuild(dir);
}
