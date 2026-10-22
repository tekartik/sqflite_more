import 'package:material_ui/material_ui.dart';
import 'package:sqflite_exp1_common/src/app/exp1_setup.dart';
import 'package:sqflite_exp1_common/src/db/exp1_db.dart';
import 'package:sqflite_exp1_common/src/model/exp1_model.dart';
import 'package:sqflite_exp1_common/src/ui/exp1_dialogs.dart';
import 'package:sqflite_exp1_common/src/ui/exp1_id.dart';

/// The exp1 app: todo lists and their tasks.
class Exp1App extends StatelessWidget {
  /// Variant setup.
  final Exp1Setup setup;

  /// Open database.
  final Exp1Db db;

  /// App on [db].
  const Exp1App({super.key, required this.setup, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exp1 ${setup.variant}',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: Exp1ListsPage(setup: setup, db: db),
    );
  }
}

/// Todo lists page.
class Exp1ListsPage extends StatefulWidget {
  /// Variant setup.
  final Exp1Setup setup;

  /// Open database.
  final Exp1Db db;

  /// Lists of [db].
  const Exp1ListsPage({super.key, required this.setup, required this.db});

  @override
  State<Exp1ListsPage> createState() => _Exp1ListsPageState();
}

class _Exp1ListsPageState extends State<Exp1ListsPage> {
  Exp1Db get db => widget.db;
  late final _lists = db.onLists();

  Future<void> _addList() async {
    var name = await showExp1NameDialog(
      context,
      title: 'New list',
      label: 'Name',
    );
    if (name != null) {
      await db.addList(name);
    }
  }

  Future<void> _onMenu(String value) async {
    switch (value) {
      case Exp1Ids.menuReset:
        await db.reset();
      case Exp1Ids.menuHoldTransaction:
        await db.holdTransaction();
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Exp1 · ${widget.setup.variant}'),
        actions: [
          Exp1Id(
            Exp1Ids.menu,
            child: PopupMenuButton<String>(
              onSelected: _onMenu,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: Exp1Ids.menuReset,
                  child: Exp1Id(
                    Exp1Ids.menuReset,
                    child: const Text('Reset demo database'),
                  ),
                ),
                PopupMenuItem(
                  value: Exp1Ids.menuHoldTransaction,
                  child: Exp1Id(
                    Exp1Ids.menuHoldTransaction,
                    child: const Text('Hold a write transaction'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              '${widget.setup.implementation}\n${db.path}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (db.transactionHeld)
            Exp1Id(
              Exp1Ids.heldBanner,
              child: Container(
                color: theme.colorScheme.errorContainer,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Write transaction held, the database is locked: '
                  'hot restart or restart the app.',
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<TodoList>>(
              stream: _lists,
              builder: (context, snapshot) {
                var lists = snapshot.data;
                if (lists == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  children: [
                    for (var list in lists)
                      Exp1Id(
                        Exp1Ids.list(list.id),
                        child: ListTile(
                          title: Text(list.name),
                          subtitle: Text(
                            '${list.taskCount} tasks, ${list.doneCount} done',
                          ),
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  Exp1TasksPage(db: db, listId: list.id),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Exp1Id(
        Exp1Ids.addList,
        child: FloatingActionButton(
          onPressed: _addList,
          tooltip: 'New list',
          child: const Icon(Icons.playlist_add),
        ),
      ),
    );
  }
}

/// Tasks of a todo list.
class Exp1TasksPage extends StatefulWidget {
  /// Open database.
  final Exp1Db db;

  /// Todo list id.
  final int listId;

  /// Tasks of [listId].
  const Exp1TasksPage({super.key, required this.db, required this.listId});

  @override
  State<Exp1TasksPage> createState() => _Exp1TasksPageState();
}

class _Exp1TasksPageState extends State<Exp1TasksPage> {
  Exp1Db get db => widget.db;
  int get listId => widget.listId;
  late final _list = db.onList(listId);
  late final _tasks = db.onTasks(listId);

  Future<void> _addTask(BuildContext context) async {
    var title = await showExp1NameDialog(
      context,
      title: 'New task',
      label: 'Title',
    );
    if (title != null) {
      await db.addTask(listId, title);
    }
  }

  Future<void> _deleteList(BuildContext context, TodoList list) async {
    if (await showExp1ConfirmDialog(
      context,
      title: 'Delete ${list.name}?',
      content: 'Its ${list.taskCount} tasks are deleted too.',
    )) {
      await db.deleteList(listId);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TodoList?>(
      stream: _list,
      builder: (context, snapshot) {
        var list = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            leading: Exp1Id(Exp1Ids.back, child: const BackButton()),
            title: Text(list?.name ?? ''),
            actions: [
              if (list != null)
                Exp1Id(
                  Exp1Ids.deleteList,
                  child: IconButton(
                    tooltip: 'Delete list',
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteList(context, list),
                  ),
                ),
            ],
          ),
          body: StreamBuilder<List<Task>>(
            stream: _tasks,
            builder: (context, snapshot) {
              var tasks = snapshot.data;
              if (tasks == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                children: [
                  for (var task in tasks)
                    ListTile(
                      leading: Exp1Id(
                        Exp1Ids.taskDone(task.id),
                        child: Checkbox(
                          value: task.done,
                          onChanged: (done) =>
                              db.setTaskDone(task.id, done ?? false),
                        ),
                      ),
                      title: Text(
                        task.title,
                        style: task.done
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
                      trailing: Exp1Id(
                        Exp1Ids.taskDelete(task.id),
                        child: IconButton(
                          tooltip: 'Delete task',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => db.deleteTask(task.id),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          floatingActionButton: Exp1Id(
            Exp1Ids.addTask,
            child: FloatingActionButton(
              onPressed: () => _addTask(context),
              tooltip: 'New task',
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}
