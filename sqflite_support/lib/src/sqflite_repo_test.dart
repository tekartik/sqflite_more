import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_flutter_build/device_test.dart';
import 'package:test/test.dart';

import 'sqflite_suite_run.dart';

/// The env var giving the sqflite repo (default: next to sqflite_more).
const sqfliteRepoDirEnvKey = 'SQFLITE_REPO_DIR';

/// The env var giving the Android AVD to launch when no device is online
/// (needed when the machine has several AVDs), for example `Pixel_9`.
const sqfliteTestAvdEnvKey = 'SQFLITE_TEST_AVD';

/// The env var giving the iOS simulator to use, a name or a UDID, for
/// example `iPhone 17` (default: the booted one, else the first iPhone of
/// the latest runtime).
const sqfliteTestSimulatorEnvKey = 'SQFLITE_TEST_SIMULATOR';

String? _envVar(String key) {
  var value = ShellEnvironment().vars[key];
  return (value?.isEmpty ?? true) ? null : value;
}

/// The sqflite repo: [sqfliteRepoDirEnvKey] when set, else the `sqflite`
/// folder next to the sqflite_more checkout holding [sqfliteSupportDir]
/// (the current directory by default, the one of `dart test`).
String sqfliteRepoDir({String? sqfliteSupportDir}) =>
    _envVar(sqfliteRepoDirEnvKey) ??
    normalize(
      join(
        dirname(dirname(absolute(sqfliteSupportDir ?? Directory.current.path))),
        'sqflite',
      ),
    );

/// The test apps of the sqflite repo at [sqfliteDir], by short name: `ffi`
/// (packages_flutter/sqflite_ffi_test_app) and `plugin`
/// (packages_flutter/sqflite_plugin_test_app).
Map<String, SqfliteSuiteApp> sqfliteRepoTestApps(String sqfliteDir) {
  SqfliteSuiteApp app(
    String name,
    String testRunner,
    List<SqfliteSuiteTarget> targets,
  ) => SqfliteSuiteApp(
    path: join(sqfliteDir, 'packages_flutter', name),
    targets: targets,
    deviceTest: 'integration_test',
    testRunner: testRunner,
    // As their own flutter create (sqflite_support flutter_device.dart).
    flutterCreateArguments: ['--org', 'com.tekartik', '--empty'],
  );
  return {
    'ffi':
        app('sqflite_ffi_test_app', 'lib/main_sqflite_ffi_test_runner.dart', [
          SqfliteSuiteTarget.android,
          SqfliteSuiteTarget.ios,
          SqfliteSuiteTarget.linux,
          SqfliteSuiteTarget.macos,
          SqfliteSuiteTarget.windows,
        ]),
    'plugin': app(
      'sqflite_plugin_test_app',
      'lib/main_sqflite_plugin_test_runner.dart',
      [
        SqfliteSuiteTarget.android,
        SqfliteSuiteTarget.ios,
        SqfliteSuiteTarget.macos,
      ],
    ),
  };
}

/// The summary printed by package:test once the tests are done, for example
/// `00:08 +160: All tests passed!`, `00:08 +167 ~14: All other tests passed!`
/// (some skipped) or `00:08 +159 ~14 -1: Some tests failed.` (prefixed by
/// `flutter: ` or `I/flutter (1234): ` in the `flutter run` output).
final _testsDoneRegExp = RegExp(
  r'\d+:\d+ \+\d+.*: (All tests passed!|All other tests passed!|'
  r'Some tests failed\.)',
);

/// Color escape sequences of the test output: the escape character itself
/// (android logcat), or escaped as the text `\^[` (the iOS simulator log).
final _ansiEscapeRegExp = RegExp(r'(\x1B|\\\^\[)\[[0-9;]*m');

/// The exit code if [line] is the summary printed once the tests are done:
/// 0 if all the tests passed, 1 if some failed, otherwise null.
int? flutterTestRunnerDoneExitCode(String line) {
  var match = _testsDoneRegExp.firstMatch(
    line.replaceAll(_ansiEscapeRegExp, ''),
  );
  if (match == null) {
    return null;
  }
  return match.group(1)!.startsWith('All') ? 0 : 1;
}

/// Runs the console test runner [target] of the flutter app [path]
/// (`flutter run -d <deviceId> -t <target>`), the tests print their results
/// in the console, and quits (`q`) once they are done (the sqflite repo
/// `runFlutterTestRunner`, from another directory).
///
/// Returns 0 if all the tests passed, 1 if some failed,
/// [flutterTestRunnerIdleExitCode] when the end of the tests was not seen,
/// otherwise the exit code of `flutter run` (a build error).
///
/// Once the app runs, no output for [idleTimeout] quits it: the end of the
/// tests is never seen on Android, the test reporter of the app writing to
/// stdout, which logcat does not show (only `print` reaches it); on iOS the
/// stdout of the app is in its log.
Future<int> runFlutterTestRunnerIn(
  String path, {
  required String deviceId,
  required String target,
  Duration idleTimeout = const Duration(minutes: 3),
}) async {
  var input = ShellLinesController();
  var output = ShellLinesController();
  var shell = Shell(
    workingDirectory: path,
    stdin: input.binaryStream,
    stdout: output.sink,
    throwOnError: false,
  );
  int? testsExitCode;
  var idle = false;
  Timer? killTimer;
  Timer? idleTimer;
  var appRunning = false;
  void quit() {
    // Same as typing q: flutter run stops the app and exits.
    input.write('q');
    killTimer ??= Timer(const Duration(seconds: 30), shell.kill);
  }

  void onIdle() {
    idle = true;
    stderr.writeln(
      'No output for ${idleTimeout.inMinutes}m, the end of the tests was not '
      'seen (on Android the test reporter of the app writes to stdout, which '
      'logcat does not show): quitting',
    );
    quit();
  }

  var subscription = output.stream.listen((line) {
    stdout.writeln(line);
    if (testsExitCode != null || idle) {
      return;
    }
    appRunning =
        appRunning ||
        line.contains('Syncing files to device') ||
        line.contains('Dart VM Service') ||
        line.contains('Flutter run key commands');
    if (appRunning) {
      idleTimer?.cancel();
      idleTimer = Timer(idleTimeout, onIdle);
    }
    testsExitCode = flutterTestRunnerDoneExitCode(line);
    if (testsExitCode != null) {
      idleTimer?.cancel();
      quit();
    }
  });
  int done(int flutterRunExitCode) =>
      testsExitCode ??
      (idle ? flutterTestRunnerIdleExitCode : flutterRunExitCode);
  try {
    var result = await shell.runExecutableArguments('flutter', [
      'run',
      '-d',
      deviceId,
      '-t',
      target,
    ]);
    return done(result.exitCode);
  } on ShellException catch (_) {
    // Killed, flutter run did not quit.
    if (testsExitCode != null || idle) {
      return done(1);
    }
    rethrow;
  } finally {
    idleTimer?.cancel();
    killTimer?.cancel();
    input.close();
    output.close();
    await subscription.cancel();
  }
}

/// The exit code of [runFlutterTestRunnerIn] when the end of the tests was
/// not seen (no output for its idle timeout).
const flutterTestRunnerIdleExitCode = 2;

/// How the tests of an app run.
enum SqfliteRepoTestKind {
  /// `flutter test integration_test -d <device>`, results and exit code on
  /// the host.
  integrationTest,

  /// `flutter run -d <device> -t <test runner>`, results in the console,
  /// quitting once the tests are done.
  testRunner,
}

/// The result of an app run in [runSqfliteRepoTestsOnTarget].
class SqfliteRepoTestRun {
  /// The app.
  final SqfliteSuiteApp app;

  /// The target.
  final FlutterDeviceTarget target;

  /// How it ran.
  final SqfliteRepoTestKind kind;

  /// The exit code, 0 on success.
  final int exitCode;

  /// The summary of an integration test, `null` for a test runner.
  final TestJsonSummary? summary;

  /// How long it took.
  final Duration elapsed;

  /// The [kind] run of [app] on [target], ending with [exitCode]
  /// ([summary]) in [elapsed].
  SqfliteRepoTestRun({
    required this.app,
    required this.target,
    required this.kind,
    required this.exitCode,
    required this.elapsed,
    this.summary,
  });

  /// `true` when the tests passed.
  bool get isSuccess => exitCode == 0 && (summary?.isSuccess ?? true);

  @override
  String toString() =>
      '${isSuccess ? 'OK  ' : 'FAIL'} ${app.name} ${target.name} ${kind.name}:'
      '${summary == null ? ' exit code $exitCode' : ' $summary'} in '
      '${formatSqfliteSuiteElapsed(elapsed)}';
}

/// The device options from the environment ([sqfliteTestAvdEnvKey],
/// [sqfliteTestSimulatorEnvKey]), read through process_run so they can be set
/// in the user environment (`ds env var set SQFLITE_TEST_AVD Pixel_9`).
FlutterTargetDeviceOptions sqfliteTestDeviceOptionsFromEnv() =>
    FlutterTargetDeviceOptions(
      avd: _envVar(sqfliteTestAvdEnvKey),
      simulator: _envVar(sqfliteTestSimulatorEnvKey),
    );

/// Runs [kinds] of each of [apps] (in order) on one device of [target],
/// found or launched ([withFlutterTargetDevice], an emulator or a simulator
/// launched is stopped after the runs). The platform folders are created
/// first when missing. [options] defaults to
/// [sqfliteTestDeviceOptionsFromEnv].
///
/// Throws a [FlutterTargetDeviceException] when no device can be chosen.
Future<List<SqfliteRepoTestRun>> runSqfliteRepoTestsOnTarget(
  List<SqfliteSuiteApp> apps,
  FlutterDeviceTarget target, {
  required List<SqfliteRepoTestKind> kinds,
  FlutterTargetDeviceOptions? options,
}) async {
  var suiteTarget = SqfliteSuiteTarget.values.byName(target.name);
  for (var app in apps) {
    await ensureSqfliteSuitePlatform(app, suiteTarget);
  }
  return await withFlutterTargetDevice(
    target,
    (device) async {
      stdout.writeln('Device $device');
      var runs = <SqfliteRepoTestRun>[];
      for (var app in apps) {
        for (var kind in kinds) {
          stdout.writeln('== ${app.name} ${target.name} ${kind.name}');
          var stopwatch = Stopwatch()..start();
          SqfliteRepoTestRun run;
          switch (kind) {
            case SqfliteRepoTestKind.integrationTest:
              var result = await runFlutterDeviceTest(
                app.path,
                deviceId: device.id,
                test: app.deviceTest!,
              );
              run = SqfliteRepoTestRun(
                app: app,
                target: target,
                kind: kind,
                exitCode: result.exitCode,
                summary: result.summary,
                elapsed: stopwatch.elapsed,
              );
            case SqfliteRepoTestKind.testRunner:
              var exitCode = await runFlutterTestRunnerIn(
                app.path,
                deviceId: device.id,
                target: app.testRunner!,
              );
              run = SqfliteRepoTestRun(
                app: app,
                target: target,
                kind: kind,
                exitCode: exitCode,
                elapsed: stopwatch.elapsed,
              );
          }
          stdout.writeln(run);
          runs.add(run);
        }
      }
      return runs;
    },
    options: options ?? sqfliteTestDeviceOptionsFromEnv(),
    onLaunching: (id) => stdout.writeln('Launching $id...'),
  );
}

/// Declares one test (package:test) per target of [targets] running [kinds]
/// of the sqflite repo test [apps] (`ffi`, `plugin`) on one device of the
/// target ([runSqfliteRepoTestsOnTarget]), skipped when the host does not
/// support the target.
///
/// For the manual tests (`test/*_test_manual.dart`, run explicitly with
/// `dart test test/<file>`). The test fails when a run fails or no device
/// can be chosen (the message names the env var to set).
void sqfliteRepoTargetTests({
  required List<String> apps,
  required List<FlutterDeviceTarget> targets,
  required List<SqfliteRepoTestKind> kinds,
}) {
  var sqfliteDir = sqfliteRepoDir();
  var allApps = sqfliteRepoTestApps(sqfliteDir);
  for (var target in targets) {
    var targetApps = apps
        .map((name) => allApps[name]!)
        .where((app) => app.targets.any((suite) => suite.name == target.name))
        .toList();
    test(
      '${targetApps.map((app) => app.name).join(', ')} ${target.name} '
      '${kinds.map((kind) => kind.name).join(', ')}',
      () async {
        for (var app in targetApps) {
          expect(
            File(join(app.path, 'pubspec.yaml')).existsSync(),
            isTrue,
            reason: '${app.path} not found ($sqfliteRepoDirEnvKey)',
          );
        }
        List<SqfliteRepoTestRun> runs;
        try {
          runs = await runSqfliteRepoTestsOnTarget(
            targetApps,
            target,
            kinds: kinds,
          );
        } on FlutterTargetDeviceException catch (e) {
          var envKey = target == FlutterDeviceTarget.android
              ? sqfliteTestAvdEnvKey
              : sqfliteTestSimulatorEnvKey;
          fail(
            '$e\n'
            '${e.candidates.isEmpty ? '' : 'Candidates: ${e.candidates.map((c) => c.id).join(', ')}\n'}'
            'Set $envKey (ds env var set $envKey <value>)',
          );
        }
        stdout.writeln('Summary:');
        for (var run in runs) {
          stdout.writeln('  $run');
          for (var failure in run.summary?.failures ?? const []) {
            stdout.writeln('      FAIL $failure');
          }
        }
        expect(
          runs.where((run) => !run.isSuccess).map((run) => '$run'),
          isEmpty,
        );
      },
      skip: target.isSupportedOnHost
          ? (targetApps.isEmpty ? 'no app for ${target.name}' : false)
          : 'not supported on ${Platform.operatingSystem}',
      timeout: const Timeout(Duration(minutes: 40)),
    );
  }
}
