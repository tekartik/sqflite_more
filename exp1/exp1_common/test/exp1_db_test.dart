@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_exp1_common/sqflite_exp1_common.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late Exp1Db db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('exp1_db_');
    db = Exp1Db(databaseFactoryFfi, name: join(dir.path, exp1DbName));
    await db.open();
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  TodoList listNamed(List<TodoList> lists, String name) =>
      lists.firstWhere((list) => list.name == name);

  test('demo data in the views', () async {
    var lists = await db.getLists();
    expect(lists.map((list) => list.name), ['Groceries', 'Work']);
    var groceries = listNamed(lists, 'Groceries');
    expect(groceries.taskCount, 3);
    expect(groceries.doneCount, 1);
    var tasks = await db.getTasks(groceries.id);
    // To do first
    expect(tasks.map((task) => task.title), ['Bread', 'Coffee', 'Milk']);
    expect(tasks.map((task) => task.listName).toSet(), {'Groceries'});
  });

  test('add, done, delete', () async {
    var listId = await db.addList('Holidays');
    var taskId = await db.addTask(listId, 'Passport');
    await db.addTask(listId, 'Tickets');
    await db.setTaskDone(taskId, true);
    var list = (await db.getList(listId))!;
    expect(list.taskCount, 2);
    expect(list.doneCount, 1);
    expect((await db.getTasks(listId)).map((task) => task.title), [
      'Tickets',
      'Passport',
    ]);
    await db.deleteTask(taskId);
    expect((await db.getList(listId))!.taskCount, 1);
  });

  test('delete list cascades', () async {
    var groceries = listNamed(await db.getLists(), 'Groceries');
    await db.deleteList(groceries.id);
    expect(await db.getList(groceries.id), isNull);
    // No orphan task
    expect(
      await db.db.query(
        'Task',
        where: 'list_id = ?',
        whereArgs: [groceries.id],
      ),
      isEmpty,
    );
  });

  test('state and reset', () async {
    await db.addList('Extra');
    var state = await db.state();
    expect((state['lists'] as List).length, 3);
    await db.reset();
    state = await db.state();
    expect((state['lists'] as List).length, 2);
  });

  test('onLists', () async {
    var stream = db.onLists();
    var names = stream.map((lists) => lists.length).take(2).toList();
    // Wait for the first emission before changing
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await db.addList('Next');
    expect(await names, [2, 3]);
  });
}
