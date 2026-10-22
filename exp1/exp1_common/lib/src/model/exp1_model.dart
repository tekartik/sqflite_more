import 'package:sqflite_exp1_common/src/db/exp1_schema.dart';

/// A todo list read from [viewTodoList].
class TodoList {
  /// Id.
  final int id;

  /// Name.
  final String name;

  /// Number of tasks.
  final int taskCount;

  /// Number of done tasks.
  final int doneCount;

  /// From a [viewTodoList] row.
  TodoList.fromMap(Map<String, Object?> map)
    : id = map[columnId] as int,
      name = map[columnName] as String,
      taskCount = map[columnTaskCount] as int,
      doneCount = map[columnDoneCount] as int;

  /// For the scenario tool.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'taskCount': taskCount,
    'doneCount': doneCount,
  };
}

/// A task read from [viewTask].
class Task {
  /// Id.
  final int id;

  /// Todo list id.
  final int listId;

  /// Name of the todo list.
  final String listName;

  /// Title.
  final String title;

  /// Done.
  final bool done;

  /// From a [viewTask] row.
  Task.fromMap(Map<String, Object?> map)
    : id = map[columnId] as int,
      listId = map[columnListId] as int,
      listName = map[columnListName] as String,
      title = map[columnTitle] as String,
      done = (map[columnDone] as int) != 0;

  /// For the scenario tool.
  Map<String, Object?> toJson() => {'id': id, 'title': title, 'done': done};
}
