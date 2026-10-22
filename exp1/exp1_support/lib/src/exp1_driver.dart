import 'dart:async';
import 'dart:convert';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:sqflite_exp1_common/exp1_shared.dart';
import 'package:vm_service/vm_service.dart' show IsolateRef;
import 'package:vm_service/vm_service_io.dart';

/// Default timeout of the driver commands.
const exp1DriverTimeout = Duration(seconds: 30);

/// A todo list in the app state.
class Exp1StateList {
  /// Id.
  final int id;

  /// Name.
  final String name;

  /// Task count.
  final int taskCount;

  /// Done task count.
  final int doneCount;

  /// Task titles.
  final List<String> taskTitles;

  /// Done task titles.
  final List<String> doneTitles;

  Exp1StateList._(Map<String, Object?> map)
    : id = map['id'] as int,
      name = map['name'] as String,
      taskCount = map['taskCount'] as int,
      doneCount = map['doneCount'] as int,
      taskTitles = [
        for (var task in (map['tasks'] as List).cast<Map>())
          task['title'] as String,
      ],
      doneTitles = [
        for (var task in (map['tasks'] as List).cast<Map>())
          if (task['done'] == true) task['title'] as String,
      ];

  @override
  String toString() => '$name ($taskCount tasks, $doneCount done)';
}

/// The app state returned by `requestData('state')`.
class Exp1State {
  /// Raw JSON.
  final Map<String, Object?> map;

  /// From the JSON map.
  Exp1State(this.map);

  /// Variant name.
  String? get variant => map['variant'] as String?;

  /// Implementation used.
  String? get implementation => map['implementation'] as String?;

  /// True once the database is open.
  bool get ready => map['ready'] == true;

  /// True while a write transaction is held.
  bool get held => map['held'] == true;

  /// Database path.
  String? get path => map['path'] as String?;

  /// Todo lists (empty while held).
  List<Exp1StateList> get lists => [
    for (var list in (map['lists'] as List? ?? const []).cast<Map>())
      Exp1StateList._(list.cast<String, Object?>()),
  ];

  /// The list named [name], null if not found.
  Exp1StateList? list(String name) {
    for (var list in lists) {
      if (list.name == name) {
        return list;
      }
    }
    return null;
  }

  /// All the task titles.
  List<String> get taskTitles => [for (var list in lists) ...list.taskTitles];
}

/// Drives an exp1 app through flutter_driver, using the widget ids
/// ([Exp1Ids]) and `requestData('state')`.
class Exp1Driver {
  /// Driver connected to the main isolate.
  final FlutterDriver driver;

  Exp1Driver._(this.driver);

  /// Connects to the main isolate of the app at [vmServiceUri] (the sqflite
  /// isolate of sqflite_ffi is another isolate).
  static Future<Exp1Driver> connect(String vmServiceUri) async {
    var service = await vmServiceConnectUri(vmServiceUri);
    int? isolateNumber;
    try {
      // Right after a hot restart the new main isolate can take a moment.
      for (var i = 0; i < 50; i++) {
        var vm = await service.getVM();
        for (var isolate in vm.isolates ?? const <IsolateRef>[]) {
          if (isolate.name == 'main') {
            isolateNumber = int.tryParse(isolate.number ?? '');
          }
        }
        if (isolateNumber != null) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } finally {
      await service.dispose();
    }
    var driver = await FlutterDriver.connect(
      dartVmServiceUrl: vmServiceUri,
      isolateNumber: isolateNumber,
      printCommunication: false,
      logCommunicationToFile: false,
    );
    return Exp1Driver._(driver);
  }

  /// Closes the connection (not the app).
  Future<void> close() async {
    try {
      await driver.close();
    } catch (_) {
      // The isolate might be gone (restart)
    }
  }

  /// The app state.
  Future<Exp1State> state() async {
    var data = await driver.requestData('state', timeout: exp1DriverTimeout);
    return Exp1State((jsonDecode(data) as Map).cast<String, Object?>());
  }

  /// Waits for a state matching [predicate].
  Future<Exp1State> waitState(
    bool Function(Exp1State state) predicate, {
    String? reason,
    Duration timeout = exp1DriverTimeout,
  }) async {
    var stopwatch = Stopwatch()..start();
    while (true) {
      var current = await state();
      if (predicate(current)) {
        return current;
      }
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'State never matched${reason == null ? '' : ' ($reason)'}: '
          '${current.lists}',
          timeout,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Waits for the database to be open.
  Future<Exp1State> waitReady() =>
      waitState((state) => state.ready, reason: 'database open');

  /// Taps the widget [id].
  Future<void> tap(String id) =>
      driver.tap(find.byValueKey(id), timeout: exp1DriverTimeout);

  /// Waits for the widget [id].
  Future<void> waitFor(String id) =>
      driver.waitFor(find.byValueKey(id), timeout: exp1DriverTimeout);

  /// Back to the previous page.
  Future<void> back() => tap(Exp1Ids.back);

  Future<void> _enterName(String name) async {
    await tap(Exp1Ids.nameField);
    await driver.enterText(name, timeout: exp1DriverTimeout);
    await tap(Exp1Ids.dialogOk);
  }

  /// Adds a list from the lists page, returns its id.
  Future<int> addList(String name) async {
    await tap(Exp1Ids.addList);
    await _enterName(name);
    var state = await waitState(
      (state) => state.list(name) != null,
      reason: 'list $name added',
    );
    return state.list(name)!.id;
  }

  /// Opens the list [name] from the lists page.
  Future<void> openList(String name) async {
    var list = (await state()).list(name)!;
    await tap(Exp1Ids.list(list.id));
    await waitFor(Exp1Ids.addTask);
  }

  /// Adds a task from the tasks page.
  Future<void> addTask(String listName, String title) async {
    await tap(Exp1Ids.addTask);
    await _enterName(title);
    await waitState(
      (state) => state.list(listName)?.taskTitles.contains(title) ?? false,
      reason: 'task $title added',
    );
  }

  /// Toggles the task [title] of [listName] from the tasks page.
  Future<void> toggleTask(String listName, String title) async {
    var before = (await state()).list(listName)!.doneCount;
    var taskId = await _taskId(listName, title);
    await tap(Exp1Ids.taskDone(taskId));
    await waitState(
      (state) => state.list(listName)!.doneCount != before,
      reason: 'task $title toggled',
    );
  }

  Future<int> _taskId(String listName, String title) async {
    var listMap = ((await state()).map['lists'] as List).cast<Map>().firstWhere(
      (list) => list['name'] == listName,
    );
    var task = (listMap['tasks'] as List).cast<Map>().firstWhere(
      (task) => task['title'] == title,
    );
    return task['id'] as int;
  }

  /// Deletes the current list from the tasks page (back to the lists page).
  Future<void> deleteCurrentList(String name) async {
    await tap(Exp1Ids.deleteList);
    await tap(Exp1Ids.dialogOk);
    await waitState(
      (state) => state.list(name) == null,
      reason: 'list $name deleted',
    );
    await waitFor(Exp1Ids.addList);
  }

  /// Resets the demo database from the menu of the lists page.
  Future<Exp1State> reset() async {
    await tap(Exp1Ids.menu);
    await tap(Exp1Ids.menuReset);
    return waitState(
      (state) =>
          state.lists.map((list) => list.name).join(',') ==
          exp1DemoData.keys.join(','),
      reason: 'demo data after reset',
    );
  }

  /// Holds a write transaction from the menu of the lists page.
  Future<void> holdTransaction() async {
    await tap(Exp1Ids.menu);
    await tap(Exp1Ids.menuHoldTransaction);
    await waitFor(Exp1Ids.heldBanner);
    await waitState((state) => state.held, reason: 'transaction held');
  }
}
