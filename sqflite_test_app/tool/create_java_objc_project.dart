import 'package:process_run/shell.dart';

import 'create_project.dart';

Future main() async {
  var shell = Shell();
  await cleanUpProjects();
  await shell.run('flutter create .');
}
