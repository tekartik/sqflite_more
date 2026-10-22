import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_exp1_common/src/db/exp1_schema.dart';
import 'package:sqflite_exp1_common/src/model/exp1_model.dart';

/// Title of the task inserted by [Exp1Db.holdTransaction], never committed.
const exp1HeldTaskTitle = 'Held transaction task';

/// The exp1 database: todo lists and their tasks.
///
/// Reads use the `query()` helper on the views, writes use `insert()`,
/// `update()` and `delete()` on the tables. The same code runs on every
/// implementation, only the [factory] changes.
class Exp1Db {
  /// The database factory of the platform (sqflite plugin, sqflite_ffi,
  /// sqflite_common_ffi_web...).
  final DatabaseFactory factory;

  /// Database name or path, relative names resolve in the databases path of
  /// [factory].
  final String name;

  Database? _db;
  final _changes = StreamController<void>.broadcast();

  /// True once [holdTransaction] has inserted its task, the database is then
  /// locked until a restart.
  bool get transactionHeld => _transactionHeld;
  var _transactionHeld = false;

  /// Exp1 database [name] opened with [factory].
  Exp1Db(this.factory, {this.name = exp1DbName});

  /// The open database.
  Database get db => _db ?? (throw StateError('$name not open'));

  /// Opens the database, creating the schema and the demo data the first
  /// time.
  Future<void> open() async {
    _db = await factory.openDatabase(
      name,
      options: OpenDatabaseOptions(
        version: exp1DbVersion,
        onConfigure: (db) async {
          // Needed for ON DELETE CASCADE.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await createExp1Schema(db);
          await insertExp1DemoData(db);
        },
      ),
    );
  }

  /// True while open.
  bool get isOpen => _db?.isOpen ?? false;

  /// Full path of the database.
  String get path => db.path;

  /// Closes the database.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Deletes the database and re-creates the demo content.
  Future<void> reset() async {
    await close();
    await factory.deleteDatabase(name);
    await open();
    _changed();
  }

  void _changed() => _changes.add(null);

  /// Todo lists sorted by name.
  Future<List<TodoList>> getLists() async {
    var rows = await db.query(
      viewTodoList,
      orderBy: '$columnName COLLATE NOCASE, $columnId',
    );
    return rows.map(TodoList.fromMap).toList();
  }

  /// A todo list, null if deleted.
  Future<TodoList?> getList(int id) async {
    var rows = await db.query(
      viewTodoList,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : TodoList.fromMap(rows.first);
  }

  /// Tasks of a list, the ones to do first.
  Future<List<Task>> getTasks(int listId) async {
    var rows = await db.query(
      viewTask,
      where: '$columnListId = ?',
      whereArgs: [listId],
      orderBy: '$columnDone, $columnId',
    );
    return rows.map(Task.fromMap).toList();
  }

  /// Adds a todo list, returns its id.
  Future<int> addList(String name) async {
    var id = await db.insert(tableTodoList, {
      columnName: name,
      columnCreated: DateTime.now().millisecondsSinceEpoch,
    });
    _changed();
    return id;
  }

  /// Deletes a todo list and its tasks.
  Future<void> deleteList(int id) async {
    await db.delete(tableTodoList, where: '$columnId = ?', whereArgs: [id]);
    _changed();
  }

  /// Adds a task to a list, returns its id.
  Future<int> addTask(int listId, String title) async {
    var id = await db.insert(tableTask, {
      columnListId: listId,
      columnTitle: title,
      columnCreated: DateTime.now().millisecondsSinceEpoch,
    });
    _changed();
    return id;
  }

  /// Marks a task as done or to do.
  Future<void> setTaskDone(int id, bool done) async {
    await db.update(
      tableTask,
      {columnDone: done ? 1 : 0},
      where: '$columnId = ?',
      whereArgs: [id],
    );
    _changed();
  }

  /// Deletes a task.
  Future<void> deleteTask(int id) async {
    await db.delete(tableTask, where: '$columnId = ?', whereArgs: [id]);
    _changed();
  }

  /// Emits [read] now and after each change.
  Stream<T> _onChange<T>(Future<T> Function() read) {
    late StreamController<T> controller;
    StreamSubscription<void>? subscription;
    Future<void> send() async {
      var value = await read();
      if (!controller.isClosed) {
        controller.add(value);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        send();
        subscription = _changes.stream.listen((_) => send());
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  /// Todo lists, updated on changes.
  Stream<List<TodoList>> onLists() => _onChange(getLists);

  /// A todo list, updated on changes (null once deleted).
  Stream<TodoList?> onList(int id) => _onChange(() => getList(id));

  /// Tasks of a list, updated on changes.
  Stream<List<Task>> onTasks(int listId) => _onChange(() => getTasks(listId));

  /// Lists and their tasks, for the scenario tool.
  Future<Map<String, Object?>> state() async {
    var lists = await getLists();
    return {
      'path': path,
      'lists': [
        for (var list in lists)
          {
            ...list.toJson(),
            'tasks': [for (var task in await getTasks(list.id)) task.toJson()],
          },
      ],
    };
  }

  /// Starts a write transaction that never ends: a task is inserted in the
  /// first list and the transaction waits forever.
  ///
  /// Used to check a hot restart (or a restart): afterwards the task must be
  /// gone (rolled back) and the database writable again. Until then every
  /// database call of this isolate waits for the transaction.
  Future<void> holdTransaction() async {
    var listId = (await getLists()).first.id;
    var inserted = Completer<void>();
    unawaited(
      db.transaction((txn) async {
        await txn.insert(tableTask, {
          columnListId: listId,
          columnTitle: exp1HeldTaskTitle,
          columnCreated: DateTime.now().millisecondsSinceEpoch,
        });
        _transactionHeld = true;
        inserted.complete();
        await Completer<void>().future;
      }),
    );
    await inserted.future;
  }
}
