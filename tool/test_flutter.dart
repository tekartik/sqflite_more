//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

Future testFlutterDir(String dir, {List<String> analyzerDir}) async {
  analyzerDir ??= ['lib'];
  await runCmd(FlutterCmd(['packages', 'get'])..workingDirectory = dir);
  // await runCmd(FlutterCmd(['analyze']..addAll(analyzerDir))..workingDirectory = dir);
  await runCmd(FlutterCmd(['analyze'])..workingDirectory = dir);
  if (await File(join(dir, 'test')).exists()) {
    await runCmd(FlutterCmd(['test'])..workingDirectory = dir);
  }
}

Future main() async {
  testFlutterDir('sqflite_porter', analyzerDir: ['lib', 'test']);
  testFlutterDir('sqflite_server', analyzerDir: ['lib', 'test']);
  testFlutterDir('sqflite_server_app', analyzerDir: ['lib', 'test']);
  testFlutterDir('sqflite_test', analyzerDir: ['lib', 'test']);
  testFlutterDir('sqflite_test_app', analyzerDir: ['lib']);
}
