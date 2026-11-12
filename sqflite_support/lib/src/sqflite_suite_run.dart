import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:tekartik_flutter_build/device_test.dart';

/// Where a test app runs its suite.
enum SqfliteSuiteTarget {
  /// An Android device or emulator (found or launched).
  android,

  /// An iOS simulator (booted or booted for the run, DeviceHub on Xcode
  /// 27+).
  ios,

  /// The Linux desktop.
  linux,

  /// The macOS desktop.
  macos,

  /// The Windows desktop.
  windows,

  /// Chrome, headless.
  web;

  /// Its flutter device target, `null` for the web.
  FlutterDeviceTarget? get deviceTarget =>
      this == web ? null : FlutterDeviceTarget.values.byName(name);

  /// The targets supported on this host, in run order: android, ios (on
  /// macOS), the host desktop ([FlutterDeviceTarget.hostTargets]).
  static List<SqfliteSuiteTarget> get hostDeviceTargets => [
    for (var target in FlutterDeviceTarget.hostTargets)
      values.byName(target.name),
  ];

  /// The desktop target of the host.
  static SqfliteSuiteTarget get host =>
      values.byName(FlutterDeviceTarget.host.name);
}

/// A test app and its suite runners.
class SqfliteSuiteApp {
  /// The app folder (holding its `pubspec.yaml`).
  final String path;

  /// The integration test run on a device (android, ios and desktop targets),
  /// relative to [path].
  final String? deviceTest;

  /// The test run in Chrome with `dart test -p chrome` (web target),
  /// relative to [path]. The sqflite_common_ffi_web worker and
  /// `sqlite3.wasm` are set up in its folder first.
  final String? webTest;

  /// The targets supported, the first one is the default.
  final List<SqfliteSuiteTarget> targets;

  /// The console test runner run with `flutter run -t` (the tests print
  /// their results in the console), relative to [path], `null` when none.
  final String? testRunner;

  /// Added to `flutter create --platforms <target> .` when a platform
  /// folder is created (`--org com.tekartik --empty`...).
  final List<String> flutterCreateArguments;

  /// The app at [path] running [deviceTest] and [webTest] on [targets].
  SqfliteSuiteApp({
    required this.path,
    required this.targets,
    this.deviceTest,
    this.webTest,
    this.testRunner,
    this.flutterCreateArguments = const [],
  });

  /// Its folder name.
  String get name => basename(path);

  @override
  String toString() => name;

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

  /// iOS: the simulator to use (a UDID or a name), booted when needed.
  final String? simulator;

  /// Android, iOS: keep the emulator (simulator) launched running after
  /// the run.
  final bool keep;

  /// Android, iOS: launch the emulator (simulator) without a window.
  final bool noWindow;

  /// Web: the compiler (`dart2js`, `dart2wasm`), the default of
  /// `dart test` when `null`.
  final String? compiler;

  /// Prints the output of the tests (`print` events), not only the
  /// failures.
  final bool verbose;

  /// Runs on [target], filtered by [plainName], on the Android device of
  /// [serial] or [avd] or the iOS [simulator] ([keep], [noWindow]), with
  /// the web [compiler],
  /// [verbose] or not.
  SqfliteSuiteRunOptions({
    required this.target,
    this.plainName,
    this.avd,
    this.serial,
    this.simulator,
    this.keep = false,
    this.noWindow = false,
    this.compiler,
    this.verbose = false,
  });

  /// The device options of android and ios.
  FlutterTargetDeviceOptions get deviceOptions => FlutterTargetDeviceOptions(
    serial: serial,
    avd: avd,
    simulator: simulator,
    keep: keep,
    noWindow: noWindow,
  );

  /// The same options on [target].
  SqfliteSuiteRunOptions withTarget(SqfliteSuiteTarget target) =>
      SqfliteSuiteRunOptions(
        target: target,
        plainName: plainName,
        avd: avd,
        serial: serial,
        simulator: simulator,
        keep: keep,
        noWindow: noWindow,
        compiler: compiler,
        verbose: verbose,
      );
}

/// Creates the platform folder of [target] in the folder of [app] when
/// missing (`flutter create --platforms <target> .` and its
/// [SqfliteSuiteApp.flutterCreateArguments], see
/// [flutterCreatePlatformsIfMissing]).
Future<void> ensureSqfliteSuitePlatform(
  SqfliteSuiteApp app,
  SqfliteSuiteTarget target,
) async {
  await flutterCreatePlatformsIfMissing(app.path, [
    target.name,
  ], arguments: app.flutterCreateArguments);
}

/// The `--plain-name` arguments of [options].
List<String> _plainNameArguments(SqfliteSuiteRunOptions options) => [
  if (options.plainName != null) ...['--plain-name', options.plainName!],
];

/// Runs [action] with the flutter device id of the target of [options]
/// (not the web), found or launched by [withFlutterTargetDevice]; a device
/// launched is stopped after [action] unless kept.
///
/// Throws a [FlutterTargetDeviceException] when no android device or iOS
/// simulator can be chosen.
Future<T> withSqfliteSuiteDevice<T>(
  SqfliteSuiteRunOptions options,
  Future<T> Function(String deviceId) action,
) {
  var target = options.target.deviceTarget;
  if (target == null) {
    throw ArgumentError('web is not a flutter device');
  }
  return withFlutterTargetDevice(
    target,
    (device) {
      stdout.writeln('Device $device');
      return action(device.id);
    },
    options: options.deviceOptions,
    onLaunching: (id) => stdout.writeln('Launching $id...'),
  );
}

/// Runs the device test of [app] on the flutter device [deviceId] (of the
/// target of [options]): `flutter test <deviceTest> -d <deviceId>`, its
/// platform folder being created first when missing.
Future<TestJsonSummary> runSqfliteSuiteOnDevice(
  SqfliteSuiteApp app,
  SqfliteSuiteRunOptions options,
  String deviceId,
) async {
  await ensureSqfliteSuitePlatform(app, options.target);
  var result = await runFlutterDeviceTest(
    app.path,
    deviceId: deviceId,
    test: app.deviceTest!,
    plainName: options.plainName,
    verbose: options.verbose,
  );
  return result.summary;
}

/// Runs the suite of [app] on the target of [options] and returns its
/// summary (`done` is `false` when the command failed without a json
/// `done` event).
///
/// - android, ios, linux, macos, windows: [runSqfliteSuiteOnDevice] on the
///   device of [withSqfliteSuiteDevice].
/// - web: the sqflite_common_ffi_web setup in the folder of the web test,
///   then `dart test -p chrome <webTest>`.
///
/// Throws an [ArgumentError] when [app] does not support the target.
Future<TestJsonSummary> runSqfliteSuite(
  SqfliteSuiteApp app,
  SqfliteSuiteRunOptions options,
) async {
  var target = options.target;
  if (!app.targets.contains(target)) {
    throw ArgumentError('${target.name} not supported (${app.targets})');
  }
  if (target == SqfliteSuiteTarget.web) {
    var webTest = app.webTest!;
    await Shell(workingDirectory: app.path).run(
      'dart run sqflite_common_ffi_web:setup --dir ${shellArgument(dirname(webTest))}',
    );
    var result = await runTestJsonCommand(
      'dart',
      [
        'test',
        '-p',
        'chrome',
        if (options.compiler != null) ...['--compiler', options.compiler!],
        '-r',
        'json',
        ..._plainNameArguments(options),
        webTest,
      ],
      workingDirectory: app.path,
      verbose: options.verbose,
    );
    return result.summary;
  }
  // Platform folder first, not to keep a launched device waiting.
  await ensureSqfliteSuitePlatform(app, target);
  return await withSqfliteSuiteDevice(
    options,
    (deviceId) => runSqfliteSuiteOnDevice(app, options, deviceId),
  );
}

/// The result of an app on a target in [runSqfliteSuites].
class SqfliteSuiteResult {
  /// The app.
  final SqfliteSuiteApp app;

  /// The target.
  final SqfliteSuiteTarget target;

  /// Its summary, `null` when it could not run ([error]).
  final TestJsonSummary? summary;

  /// Why it could not run (no device...).
  final Object? error;

  /// How long it took.
  final Duration elapsed;

  /// The [summary] (or [error]) of [app] on [target] in [elapsed].
  SqfliteSuiteResult({
    required this.app,
    required this.target,
    required this.elapsed,
    this.summary,
    this.error,
  });

  /// `true` when it ran and all its tests passed.
  bool get isSuccess => summary?.isSuccess ?? false;

  @override
  String toString() =>
      '${app.name} ${target.name}: ${summary ?? 'ERROR $error'} in '
      '${formatSqfliteSuiteElapsed(elapsed)}';
}

/// `<m>m<ss>s`.
String formatSqfliteSuiteElapsed(Duration elapsed) =>
    '${elapsed.inMinutes}m${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}s';

/// Runs the suites of [apps] on each of [targets] (the [options] being
/// applied with each target, [SqfliteSuiteRunOptions.withTarget]), skipping
/// the apps not supporting a target.
///
/// On android and ios a single device is used (found, launched or booted)
/// for all the apps, their platform folders being created first. A target
/// without device gets an error result for its apps, the next target is
/// run. [onResult] is called as each result comes.
Future<List<SqfliteSuiteResult>> runSqfliteSuites(
  List<SqfliteSuiteApp> apps,
  List<SqfliteSuiteTarget> targets,
  SqfliteSuiteRunOptions options, {
  void Function(SqfliteSuiteResult result)? onResult,
}) async {
  var results = <SqfliteSuiteResult>[];
  void add(SqfliteSuiteResult result) {
    results.add(result);
    onResult?.call(result);
  }

  for (var target in targets) {
    var targetApps = apps.where((app) => app.targets.contains(target)).toList();
    if (targetApps.isEmpty) {
      continue;
    }
    var targetOptions = options.withTarget(target);
    if (target == SqfliteSuiteTarget.web) {
      for (var app in targetApps) {
        var stopwatch = Stopwatch()..start();
        var summary = await runSqfliteSuite(app, targetOptions);
        add(
          SqfliteSuiteResult(
            app: app,
            target: target,
            summary: summary,
            elapsed: stopwatch.elapsed,
          ),
        );
      }
      continue;
    }
    for (var app in targetApps) {
      await ensureSqfliteSuitePlatform(app, target);
    }
    var done = <SqfliteSuiteApp>{};
    var stopwatch = Stopwatch()..start();
    try {
      await withSqfliteSuiteDevice(targetOptions, (deviceId) async {
        for (var app in targetApps) {
          stdout.writeln('== ${app.name} ${target.name}');
          stopwatch.reset();
          var summary = await runSqfliteSuiteOnDevice(
            app,
            targetOptions,
            deviceId,
          );
          done.add(app);
          add(
            SqfliteSuiteResult(
              app: app,
              target: target,
              summary: summary,
              elapsed: stopwatch.elapsed,
            ),
          );
        }
      });
    } on FlutterTargetDeviceException catch (e) {
      // No android device or iOS simulator to use.
      stderr.writeln(_deviceExceptionText(e));
      for (var app in targetApps.where((app) => !done.contains(app))) {
        add(
          SqfliteSuiteResult(
            app: app,
            target: target,
            error: e.message,
            elapsed: Duration.zero,
          ),
        );
      }
    }
  }
  return results;
}

/// Adds the options of [SqfliteSuiteRunOptions] (but `target`) to [parser].
void addSqfliteSuiteRunOptions(ArgParser parser) {
  parser
    ..addOption(
      'plain-name',
      abbr: 'N',
      help: 'Run only the tests whose name contains it',
    )
    ..addOption('avd', help: 'android: AVD to use (running or launched)')
    ..addOption('serial', abbr: 's', help: 'android: online device to use')
    ..addOption(
      'simulator',
      help: 'ios: simulator name or UDID (booted or booted for the run)',
    )
    ..addFlag(
      'keep',
      abbr: 'k',
      negatable: false,
      help: 'android, ios: keep the emulator (simulator) launched running',
    )
    ..addFlag(
      'window',
      defaultsTo: true,
      help: 'android, ios: show the emulator window (DeviceHub on iOS)',
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
}

/// The options of [results] on [target] (parsed with a parser set up by
/// [addSqfliteSuiteRunOptions]).
SqfliteSuiteRunOptions sqfliteSuiteRunOptionsFromArgResults(
  ArgResults results,
  SqfliteSuiteTarget target,
) => SqfliteSuiteRunOptions(
  target: target,
  plainName: results.option('plain-name'),
  avd: results.option('avd'),
  serial: results.option('serial'),
  simulator: results.option('simulator'),
  keep: results.flag('keep'),
  noWindow: !results.flag('window'),
  compiler: results.option('compiler'),
  verbose: results.flag('verbose'),
);

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
    );
  addSqfliteSuiteRunOptions(parser);
  var results = parser.parse(args);
  if (results.flag('help')) {
    stdout.writeln('Runs the shared sqflite_common_test suite of ${app.name}');
    stdout.writeln(parser.usage);
    return;
  }
  var options = sqfliteSuiteRunOptionsFromArgResults(
    results,
    SqfliteSuiteTarget.values.byName(results.option('target')!),
  );
  var stopwatch = Stopwatch()..start();
  TestJsonSummary summary;
  try {
    summary = await runSqfliteSuite(app, options);
  } on FlutterTargetDeviceException catch (e) {
    // No android device or iOS simulator to use.
    stderr.writeln(_deviceExceptionText(e));
    exitCode = 1;
    return;
  }
  stdout.writeln(
    '${app.name} ${options.target.name}: $summary in '
    '${formatSqfliteSuiteElapsed(stopwatch.elapsed)}',
  );
  for (var failure in summary.failures) {
    stdout.writeln('  FAIL $failure');
  }
  if (!summary.isSuccess) {
    exitCode = 1;
  }
}

/// The message of [e] and its candidates.
String _deviceExceptionText(FlutterTargetDeviceException e) => [
  e.message,
  if (e.candidates.isNotEmpty)
    'Candidates: ${e.candidates.map((c) => '${c.id} (${c.name})').join(', ')}',
].join('\n');
