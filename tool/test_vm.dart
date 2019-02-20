//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

Future testDir(String dir, {List<String> analyzerDir}) async {
  analyzerDir ??= ['lib'];
  await runCmd(PubCmd(['get'])..workingDirectory = dir);
  // await runCmd(FlutterCmd(['analyze']..addAll(analyzerDir))..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['--fatal-warnings', '--fatal-infos', '.'])
    ..workingDirectory = dir);
  if (await File(join(dir, 'test')).exists()) {
    await runCmd(PubCmd(['run", ' 'test'])..workingDirectory = dir);
  }
}

Future main() async {
  testDir(join('alt', 'sqflite_local_test'), analyzerDir: ['test']);
  testDir(join('alt', 'sqflite_github_test'), analyzerDir: ['test']);
}
