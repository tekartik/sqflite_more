// Runs the integration tests of the sqflite repo test apps
// (packages_flutter/sqflite_ffi_test_app and sqflite_plugin_test_app, as
// their tool/run_integration_test*.dart do: `flutter test integration_test
// -d <device>`) on each target: Android (the running emulator or one
// launched), iOS (the booted simulator or one booted, DeviceHub) and the
// host desktop.
//
//   dart run tool/sqflite_integration_test_run.dart [--help]
//   dart run tool/sqflite_integration_test_run.dart -t ios -t macos -a plugin
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:sqflite_support/sqflite_suite_run.dart';

/// The host desktop target.
SqfliteSuiteTarget get hostTarget => Platform.isMacOS
    ? SqfliteSuiteTarget.macos
    : Platform.isWindows
    ? SqfliteSuiteTarget.windows
    : SqfliteSuiteTarget.linux;

/// The targets runnable from this host, in run order.
List<SqfliteSuiteTarget> get hostTargets => [
  SqfliteSuiteTarget.android,
  if (Platform.isMacOS) SqfliteSuiteTarget.ios,
  hostTarget,
];

/// The test apps of the sqflite repo at [sqfliteDir], by short name.
Map<String, SqfliteSuiteApp> sqfliteRepoTestApps(String sqfliteDir) {
  SqfliteSuiteApp app(String name, List<SqfliteSuiteTarget> targets) =>
      SqfliteSuiteApp(
        path: join(sqfliteDir, 'packages_flutter', name),
        targets: targets,
        deviceTest: 'integration_test',
        // As their own flutter create (sqflite_support flutter_device.dart).
        flutterCreateArguments: ['--org', 'com.tekartik', '--empty'],
      );
  return {
    'ffi': app('sqflite_ffi_test_app', [
      SqfliteSuiteTarget.android,
      SqfliteSuiteTarget.ios,
      SqfliteSuiteTarget.linux,
      SqfliteSuiteTarget.macos,
      SqfliteSuiteTarget.windows,
    ]),
    'plugin': app('sqflite_plugin_test_app', [
      SqfliteSuiteTarget.android,
      SqfliteSuiteTarget.ios,
      SqfliteSuiteTarget.macos,
    ]),
  };
}

Future<void> main(List<String> args) async {
  // sqflite_more/sqflite_support/tool/<script>: sqflite is next to
  // sqflite_more.
  var sqfliteMoreDir = dirname(dirname(dirname(Platform.script.toFilePath())));
  var parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Usage help')
    ..addMultiOption(
      'target',
      abbr: 't',
      allowed: {'all', 'host', ...hostTargets.map((target) => target.name)},
      defaultsTo: ['all'],
      help:
          'Where to run, repeatable (all: ${hostTargets.map((t) => t.name).join(', ')}; '
          'host: ${hostTarget.name})',
    )
    ..addMultiOption(
      'app',
      abbr: 'a',
      allowed: ['ffi', 'plugin'],
      defaultsTo: ['ffi', 'plugin'],
      help: 'The test apps to run, repeatable',
    )
    ..addOption(
      'sqflite',
      defaultsTo: join(dirname(sqfliteMoreDir), 'sqflite'),
      help: 'The sqflite repo',
    );
  addSqfliteSuiteRunOptions(parser);
  var results = parser.parse(args);
  if (results.flag('help')) {
    stdout.writeln(
      'Runs the integration tests of the sqflite repo test apps on each '
      'target',
    );
    stdout.writeln(parser.usage);
    return;
  }
  var sqfliteDir = normalize(absolute(results.option('sqflite')!));
  var allApps = sqfliteRepoTestApps(sqfliteDir);
  var apps = results.multiOption('app').map((name) => allApps[name]!).toList();
  for (var app in apps) {
    if (!File(join(app.path, 'pubspec.yaml')).existsSync()) {
      stderr.writeln('${app.path} not found (--sqflite <dir>)');
      exitCode = 1;
      return;
    }
  }
  var targetNames = results.multiOption('target');
  var targets = hostTargets.where((target) {
    return targetNames.contains('all') ||
        targetNames.contains(target.name) ||
        (targetNames.contains('host') && target == hostTarget);
  }).toList();

  var stopwatch = Stopwatch()..start();
  var suiteResults = await runSqfliteSuites(
    apps,
    targets,
    sqfliteSuiteRunOptionsFromArgResults(results, targets.first),
    onResult: (result) => stdout.writeln(result),
  );
  stdout.writeln(
    '\nSummary (${formatSqfliteSuiteElapsed(stopwatch.elapsed)}, $sqfliteDir)',
  );
  for (var result in suiteResults) {
    stdout.writeln('${result.isSuccess ? 'OK  ' : 'FAIL'} $result');
    for (var failure in result.summary?.failures ?? const <TestJsonFailure>[]) {
      stdout.writeln('       FAIL $failure');
    }
  }
  if (suiteResults.isEmpty || suiteResults.any((result) => !result.isSuccess)) {
    exitCode = 1;
  }
}
