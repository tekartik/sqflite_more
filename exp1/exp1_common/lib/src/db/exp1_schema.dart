import 'package:sqflite_common/sqlite_api.dart';

/// Database name, relative to the databases path of the factory.
const exp1DbName = 'exp1.db';

/// Schema version.
const exp1DbVersion = 1;

/// Todo lists table.
const tableTodoList = 'TodoList';

/// Tasks table, each task belongs to a todo list.
const tableTask = 'Task';

/// Todo lists with their task counts (read only).
const viewTodoList = 'TodoListView';

/// Tasks with the name of their list (read only).
const viewTask = 'TaskView';

/// Primary key column.
const columnId = 'id';

/// Name column (todo list).
const columnName = 'name';

/// Creation time column (milliseconds since epoch).
const columnCreated = 'created';

/// Todo list id column (task).
const columnListId = 'list_id';

/// Title column (task).
const columnTitle = 'title';

/// Done column (task, 0 or 1).
const columnDone = 'done';

/// Task count column (todo list view).
const columnTaskCount = 'task_count';

/// Done task count column (todo list view).
const columnDoneCount = 'done_count';

/// List name column (task view).
const columnListName = 'list_name';

/// Creates the tables and views.
///
/// The views hold the joins and aggregates once, so that the app reads with
/// the `query()` helper (no raw SQL) and writes with `insert()`, `update()`
/// and `delete()` on the tables.
Future<void> createExp1Schema(DatabaseExecutor db) async {
  var batch = db.batch();
  batch.execute('''
CREATE TABLE $tableTodoList (
  $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
  $columnName TEXT NOT NULL,
  $columnCreated INTEGER NOT NULL
)''');
  // Deleting a list deletes its tasks (PRAGMA foreign_keys = ON in
  // onConfigure).
  batch.execute('''
CREATE TABLE $tableTask (
  $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
  $columnListId INTEGER NOT NULL
    REFERENCES $tableTodoList($columnId) ON DELETE CASCADE,
  $columnTitle TEXT NOT NULL,
  $columnDone INTEGER NOT NULL DEFAULT 0,
  $columnCreated INTEGER NOT NULL
)''');
  batch.execute('CREATE INDEX TaskListId ON $tableTask ($columnListId)');
  batch.execute('''
CREATE VIEW $viewTodoList AS
  SELECT l.$columnId, l.$columnName, l.$columnCreated,
    COUNT(t.$columnId) AS $columnTaskCount,
    COALESCE(SUM(t.$columnDone), 0) AS $columnDoneCount
  FROM $tableTodoList l
  LEFT JOIN $tableTask t ON t.$columnListId = l.$columnId
  GROUP BY l.$columnId''');
  batch.execute('''
CREATE VIEW $viewTask AS
  SELECT t.$columnId, t.$columnListId, t.$columnTitle, t.$columnDone,
    t.$columnCreated, l.$columnName AS $columnListName
  FROM $tableTask t
  JOIN $tableTodoList l ON l.$columnId = t.$columnListId''');
  await batch.commit(noResult: true);
}

/// Demo content, inserted on creation and reset.
const exp1DemoData = <String, List<String>>{
  'Groceries': ['Milk', 'Bread', 'Coffee'],
  'Work': ['Review pull request'],
};

/// Inserts [exp1DemoData] using the insert helper, the first task of each
/// list done.
Future<void> insertExp1DemoData(DatabaseExecutor db) async {
  var now = DateTime.now().millisecondsSinceEpoch;
  for (var entry in exp1DemoData.entries) {
    var listId = await db.insert(tableTodoList, {
      columnName: entry.key,
      columnCreated: now,
    });
    var first = true;
    for (var title in entry.value) {
      await db.insert(tableTask, {
        columnListId: listId,
        columnTitle: title,
        columnDone: first ? 1 : 0,
        columnCreated: now,
      });
      first = false;
    }
  }
}
