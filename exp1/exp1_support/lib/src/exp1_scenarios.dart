import 'dart:io';

import 'package:sqflite_exp1_common/exp1_shared.dart';
import 'package:sqflite_exp1_support/src/exp1_driver.dart';
import 'package:sqflite_exp1_support/src/exp1_variants.dart';
import 'package:sqflite_exp1_support/src/flutter_run_machine.dart';

/// A failed check.
class Exp1ScenarioFailure implements Exception {
  /// What failed.
  final String message;

  /// Failure [message].
  Exp1ScenarioFailure(this.message);

  @override
  String toString() => 'Check failed: $message';
}

/// A running app (`flutter run --machine` + driver) of a variant on a
/// device, restarted by the scenarios.
class Exp1Session {
  /// Variant.
  final Exp1Variant variant;

  /// Device.
  final Exp1Device device;

  /// Verbose output.
  final bool verbose;

  FlutterRunMachine? _run;
  Exp1Driver? _driver;

  /// Session of [variant] on [device], not launched yet.
  Exp1Session(this.variant, this.device, {this.verbose = false});

  /// The driver of the running app.
  Exp1Driver get driver => _driver ?? (throw StateError('not launched'));

  /// Prints a step.
  void step(String message) => stdout.writeln('    $message');

  /// Throws an [Exp1ScenarioFailure] unless [condition].
  void check(bool condition, String message) {
    if (!condition) {
      throw Exp1ScenarioFailure(message);
    }
    step('ok: $message');
  }

  /// Launches the app (debug, driver extension enabled).
  Future<void> launch() async {
    step('launch (flutter run -d ${device.id})');
    _run = await FlutterRunMachine.start(
      appDir: variant.dir,
      deviceId: device.id,
      arguments: [
        '--dart-define=EXP1_DRIVER=true',
        if (device.platform == 'web') '--web-port=${variant.webPort}',
      ],
      verbose: verbose,
    );
    await _connect();
  }

  Future<void> _connect() async {
    _driver = await Exp1Driver.connect(_run!.vmServiceUri);
    var state = await driver.waitReady();
    step('connected: ${state.implementation}, ${state.path}');
  }

  /// Hot restart, then reconnects to the new main isolate.
  Future<void> hotRestart() async {
    step('hot restart');
    await _driver?.close();
    await _run!.hotRestart();
    await _connect();
  }

  /// Stops and launches the app again.
  Future<void> restart() async {
    step('restart (stop and launch)');
    await stop();
    await launch();
  }

  /// Saves a screenshot of the app (png) in [path], for a failure.
  Future<void> screenshot(String path) async {
    try {
      var bytes = await driver.driver.screenshot();
      var file = File(path);
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      step('screenshot: $path');
    } catch (e) {
      step('no screenshot: $e');
    }
  }

  /// Stops the app.
  Future<void> stop() async {
    await _driver?.close();
    _driver = null;
    await _run?.stop();
    _run = null;
  }
}

/// A scenario run on a launched [Exp1Session].
abstract class Exp1Scenario {
  /// Name used on the command line.
  String get name;

  /// What it checks.
  String get description;

  /// Runs it.
  Future<void> run(Exp1Session session);
}

/// Lists and tasks through the UI, counts through the views.
class Exp1CrudScenario implements Exp1Scenario {
  @override
  String get name => 'crud';

  @override
  String get description =>
      'reset, add a list and tasks, toggle, delete (counts read from the views)';

  @override
  Future<void> run(Exp1Session session) async {
    var driver = session.driver;
    var state = await driver.reset();
    var groceries = state.list('Groceries')!;
    session.check(
      groceries.taskCount == 3 && groceries.doneCount == 1,
      'demo data: $groceries',
    );
    const name = 'Scenario list';
    await driver.addList(name);
    await driver.openList(name);
    await driver.addTask(name, 'First');
    await driver.addTask(name, 'Second');
    await driver.toggleTask(name, 'First');
    var list = (await driver.state()).list(name)!;
    session.check(
      list.taskCount == 2 && list.doneCount == 1,
      'list counts: $list',
    );
    await driver.deleteCurrentList(name);
    state = await driver.state();
    session.check(
      state.list(name) == null && state.lists.length == exp1DemoData.length,
      'list deleted with its tasks: ${state.lists}',
    );
  }
}

/// Checks after a restart or a hot restart while a transaction was held.
Future<void> _checkAfterHeldRestart(Exp1Session session, String name) async {
  var driver = session.driver;
  var state = await driver.state();
  session.check(!state.held, 'no transaction held after the restart');
  session.check(state.list(name) != null, 'list $name still there');
  session.check(
    !state.taskTitles.contains(exp1HeldTaskTitle),
    'held transaction rolled back',
  );
  // The database must be writable.
  await driver.openList(name);
  await driver.addTask(name, 'Written after restart');
  await driver.back();
  await driver.waitFor(Exp1Ids.addList);
  session.check(true, 'database writable');
}

/// Data and write lock after a hot restart.
class Exp1HotRestartScenario implements Exp1Scenario {
  @override
  String get name => 'hot-restart';

  @override
  String get description =>
      'add a list, hold a write transaction, hot restart: the list is kept, '
      'the transaction rolled back, the database writable';

  @override
  Future<void> run(Exp1Session session) async {
    const name = 'Before hot restart';
    await session.driver.reset();
    await session.driver.addList(name);
    await session.driver.holdTransaction();
    session.step('write transaction held');
    await session.hotRestart();
    await _checkAfterHeldRestart(session, name);
  }
}

/// Data and write lock after a restart of the app.
class Exp1RestartScenario implements Exp1Scenario {
  @override
  String get name => 'restart';

  @override
  String get description =>
      'add a list, hold a write transaction, stop and launch the app: the '
      'list is persisted, the transaction rolled back, the database writable';

  @override
  Future<void> run(Exp1Session session) async {
    const name = 'Before restart';
    await session.driver.reset();
    await session.driver.addList(name);
    await session.driver.holdTransaction();
    session.step('write transaction held');
    await session.restart();
    await _checkAfterHeldRestart(session, name);
  }
}

/// The scenarios, in run order.
final exp1Scenarios = <Exp1Scenario>[
  Exp1CrudScenario(),
  Exp1HotRestartScenario(),
  Exp1RestartScenario(),
];
