import 'package:path/path.dart';
import 'package:sqflite_support/sqflite_repo_test.dart';
import 'package:test/test.dart';

void main() {
  test('flutterTestRunnerDoneExitCode', () {
    expect(flutterTestRunnerDoneExitCode('00:08 +160: All tests passed!'), 0);
    // Some tests skipped.
    expect(
      flutterTestRunnerDoneExitCode(
        'flutter: 00:08 \x1B[32m+167\x1B[0m\x1B[33m ~14\x1B[0m: '
        'All other tests passed!\x1B[0m',
      ),
      0,
    );
    expect(
      flutterTestRunnerDoneExitCode(
        'I/flutter (1234): 00:08 +159 ~14 -1: Some tests failed.',
      ),
      1,
    );
    // The iOS simulator log escapes the escape character as `\^[`.
    expect(
      flutterTestRunnerDoneExitCode(
        r'flutter: 00:08 \^[[32m+167\^[[0m\^[[33m ~14\^[[0m: '
        r'All other tests passed!\^[[0m',
      ),
      0,
    );
    expect(
      flutterTestRunnerDoneExitCode('00:04 +134 ~8: database_factory'),
      isNull,
    );
  });
  test('sqfliteRepoTestApps', () {
    var apps = sqfliteRepoTestApps(join('top', 'sqflite'));
    expect(apps.keys, ['ffi', 'plugin']);
    expect(
      apps['plugin']!.path,
      join('top', 'sqflite', 'packages_flutter', 'sqflite_plugin_test_app'),
    );
    expect(
      apps['plugin']!.testRunner,
      'lib/main_sqflite_plugin_test_runner.dart',
    );
    expect(apps['ffi']!.testRunner, 'lib/main_sqflite_ffi_test_runner.dart');
  });
  test('sqfliteRepoDir', () {
    expect(
      sqfliteRepoDir(
        sqfliteSupportDir: join('/', 'git', 'sqflite_more', 'sqflite_support'),
      ),
      join('/', 'git', 'sqflite'),
    );
  });
}
