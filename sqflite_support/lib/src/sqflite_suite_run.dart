import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_android_utils/build_utils.dart';
import 'package:tekartik_android_utils/emulator_utils.dart';

import 'test_json_reporter.dart';

/// Where a test app runs its suite.
enum SqfliteSuiteTarget {
  /// An Android device or emulator (found or launched).
  android,

  /// The Linux desktop.
  linux,

  /// The macOS desktop.
  macos,

  /// The Windows desktop.
  windows,

  /// Chrome, headless.
  web,
}

/// A test app and its suite runners.
class SqfliteSuiteApp {
  /// The app folder (holding its `pubspec.yaml`).
  final String path;

  /// The integration test run on a device (android and desktop targets),
  /// relative to [path].
  final String? deviceTest;

  /// The test run in Chrome with `dart test -p chrome` (web target),
  /// relative to [path]. The sqflite_common_ffi_web worker and
  /// `sqlite3.wasm` are set up in its folder first.
  final String? webTest;

  /// The targets supported, the first one is the default.
  final List<SqfliteSuiteTarget> targets;

  /// The app at [path] running [deviceTest] and [webTest] on [targets].
  SqfliteSuiteApp({
    required this.path,
    required this.targets,
    this.deviceTest,
    this.webTest,
  });

  /// The app of a tool script: its folder is the parent of the `tool`
  /// folder of [scriptUri] (`Platform.script`).
  factory SqfliteSuiteApp.ofToolScript(
    Uri scriptUri, {
    required List<SqfliteSuiteTarget> targets,
    String? deviceTest,
    String? webTest,
  }) => SqfliteSuiteApp(
    path: dirname(dirname(scriptUri.toFilePath())),
    targets: targets,
    deviceTest: deviceTest,
    webTest: webTest,
  );
}

/// The options of [runSqfliteSuite].
class SqfliteSuiteRunOptions {
  /// Where to run the suite.
  final SqfliteSuiteTarget target;

  /// Runs only the tests whose name contains it (`--plain-name`).
  final String? plainName;

  /// Android: the AVD to use (its running emulator, or a new one).
  final String? avd;

  /// Android: the online device to use.
  final String? serial;

  /// Android: keep the emulator launched running after the run.
  final bool keep;

  /// Android: launch the emulator without a window.
  final bool noWindow;

  /// Web: the compiler (`dart2js`, `dart2wasm`), the default of
  /// `dart test` when `null`.
  final String? compiler;

  /// Prints the output of the tests (`print` events), not only the
  /// failures.
  final bool verbose;

  /// Runs on [target], filtered by [plainName], on the Android device of
  /// [serial] or [avd] ([keep], [noWindow]), with the web [compiler],
  /// [verbose] or not.
  SqfliteSuiteRunOptions({
    required this.target,
    this.plainName,
    this.avd,
    this.serial,
    this.keep = false,
    this.noWindow = false,
    this.compiler,
    this.verbose = false,
  });
}

/// Runs the command of [arguments] in [path], parsing its json reporter
/// output as it comes: failures (and test prints when [verbose]) are
/// printed, the other lines (a build output) are printed as is.
Future<(TestJsonSummary, int)> _runJsonTests(
  String path,
  List<String> arguments, {
  required bool verbose,
}) async {
  var parser = TestJsonReporterParser();
  var output = ShellLinesController();
  var subscription = output.stream.listen((line) {
    if (TestJsonReporterParser.isJsonEvent(line)) {
      var done = parser.addLine(line);
      if (done != null && done.isFailure) {
        stdout.writeln('FAIL ${done.name}');
        var error = done.error;
        if (error != null) {
          stdout.writeln('  ${error.split('\n').first}');
        }
      } else if (verbose && line.contains('"type":"print"')) {
        stdout.writeln(line);
      }
    } else if (line.trim().isNotEmpty) {
      stdout.writeln(line);
    }
  });
  var shell = Shell(
    workingDirectory: path,
    stdout: output.sink,
    verbose: false,
    commandVerbose: true,
    throwOnError: false,
  );
  int exitCode;
  try {
    var result = await shell.runExecutableArguments(
      arguments.first,
      arguments.sublist(1),
    );
    exitCode = result.exitCode;
  } on ShellException catch (e) {
    stderr.writeln(e.message);
    exitCode = e.result?.exitCode ?? 1;
  } finally {
    output.close();
    await subscription.cancel();
  }
  return (parser.summary, exitCode);
}

/// Creates the platform folder of [target] in [path] when missing
/// (`flutter create --platforms <target> .`).
Future<void> _ensurePlatform(String path, SqfliteSuiteTarget target) async {
  if (Directory(join(path, target.name)).existsSync()) {
    return;
  }
  // flutter create rewrites the (tracked) .metadata: keep it.
  var metadata = File(join(path, '.metadata'));
  var metadataContent = metadata.existsSync()
      ? metadata.readAsStringSync()
      : null;
  await Shell(
    workingDirectory: path,
  ).run('flutter create --platforms ${target.name} .');
  if (metadataContent != null) {
    metadata.writeAsStringSync(metadataContent);
  }
}

/// The `--plain-name` arguments of [options].
List<String> _plainNameArguments(SqfliteSuiteRunOptions options) => [
  if (options.plainName != null) ...['--plain-name', options.plainName!],
];

/// Runs the suite of [app] on the target of [options] and returns its
/// summary (`done` is `false` when the command failed without a json
/// `done` event).
///
/// - android: on the device found or launched by `withAndroidDevice`
///   (tekartik_android_utils), `flutter test <deviceTest> -d <serial>`; an
///   emulator launched is stopped after the run unless kept.
/// - linux, macos, windows: `flutter test <deviceTest> -d <target>`.
/// - web: the sqflite_common_ffi_web setup in the folder of the web test,
///   then `dart test -p chrome <webTest>`.
///
/// The platform folder is created (`flutter create`) when missing. Throws
/// an [ArgumentError] when [app] does not support the target.
Future<TestJsonSummary> runSqfliteSuite(
  SqfliteSuiteApp app,
  SqfliteSuiteRunOptions options,
) async {
  var target = options.target;
  if (!app.targets.contains(target)) {
    throw ArgumentError('${target.name} not supported (${app.targets})');
  }
  TestJsonSummary summary;
  int exitCode;
  if (target == SqfliteSuiteTarget.web) {
    var webTest = app.webTest!;
    await Shell(workingDirectory: app.path).run(
      'dart run sqflite_common_ffi_web:setup --dir ${shellArgument(dirname(webTest))}',
    );
    (summary, exitCode) = await _runJsonTests(app.path, [
      'dart',
      'test',
      '-p',
      'chrome',
      if (options.compiler != null) ...['--compiler', options.compiler!],
      '-r',
      'json',
      ..._plainNameArguments(options),
      webTest,
    ], verbose: options.verbose);
  } else {
    var deviceTest = app.deviceTest!;
    await _ensurePlatform(app.path, target);
    Future<(TestJsonSummary, int)> runOn(String device) =>
        _runJsonTests(app.path, [
          'flutter',
          'test',
          deviceTest,
          '-d',
          device,
          '-r',
          'json',
          ..._plainNameArguments(options),
        ], verbose: options.verbose);
    if (target == SqfliteSuiteTarget.android) {
      await initAndroidBuildEnvironment();
      (summary, exitCode) = await withAndroidDevice(
        (device) {
          stdout.writeln('Device $device');
          return runOn(device.serial);
        },
        serial: options.serial,
        avd: options.avd,
        keep: options.keep,
        noWindow: options.noWindow,
        onLaunching: (serial) => stdout.writeln('Launching $serial...'),
      );
    } else {
      (summary, exitCode) = await runOn(target.name);
    }
  }
  if (exitCode != 0 && summary.done == null) {
    summary = TestJsonSummary(
      passed: summary.passed,
      failed: summary.failed,
      skipped: summary.skipped,
      failures: summary.failures,
      done: false,
    );
  }
  return summary;
}

/// The `main` of a test app tool script: parses [args] (`--help`), runs
/// the suite of [app] ([runSqfliteSuite]), prints its summary and sets
/// [exitCode] (non zero when a test failed or the run did not end).
Future<void> sqfliteSuiteRunMain(List<String> args, SqfliteSuiteApp app) async {
  var parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Usage help')
    ..addOption(
      'target',
      abbr: 't',
      allowed: app.targets.map((target) => target.name),
      defaultsTo: app.targets.first.name,
      help: 'Where to run the suite',
    )
    ..addOption(
      'plain-name',
      abbr: 'N',
      help: 'Run only the tests whose name contains it',
    )
    ..addOption('avd', help: 'android: AVD to use (running or launched)')
    ..addOption('serial', abbr: 's', help: 'android: online device to use')
    ..addFlag(
      'keep',
      abbr: 'k',
      negatable: false,
      help: 'android: keep the emulator launched running',
    )
    ..addFlag(
      'window',
      defaultsTo: true,
      help: 'android: show the window of the emulator launched',
    )
    ..addOption(
      'compiler',
      allowed: ['dart2js', 'dart2wasm'],
      help: 'web: the compiler (dart test default when not set)',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Print the output of the tests too',
    );
  var results = parser.parse(args);
  if (results.flag('help')) {
    stdout.writeln(
      'Runs the shared sqflite_common_test suite of ${basename(app.path)}',
    );
    stdout.writeln(parser.usage);
    return;
  }
  var options = SqfliteSuiteRunOptions(
    target: SqfliteSuiteTarget.values.byName(results.option('target')!),
    plainName: results.option('plain-name'),
    avd: results.option('avd'),
    serial: results.option('serial'),
    keep: results.flag('keep'),
    noWindow: !results.flag('window'),
    compiler: results.option('compiler'),
    verbose: results.flag('verbose'),
  );
  var stopwatch = Stopwatch()..start();
  TestJsonSummary summary;
  try {
    summary = await runSqfliteSuite(app, options);
  } on StateError catch (e) {
    // No android device to use.
    stderr.writeln(e.message);
    exitCode = 1;
    return;
  }
  var elapsed = stopwatch.elapsed;
  stdout.writeln(
    '${basename(app.path)} ${options.target.name}: $summary in '
    '${elapsed.inMinutes}m${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}s',
  );
  for (var failure in summary.failures) {
    stdout.writeln('  FAIL $failure');
  }
  if (!summary.isSuccess) {
    exitCode = 1;
  }
}
