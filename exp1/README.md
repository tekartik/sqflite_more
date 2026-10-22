# exp1: one demo database, every sqflite implementation

A small todo app (lists and their tasks) written once and run on every
sqflite implementation, plus a scenario tool checking it end to end,
including hot restart and restart with a write transaction in progress.

## Layout

| Package | Content | Platforms |
|---|---|---|
| [exp1_common](exp1_common) | database, UI, widget ids, scenario hooks | - |
| [exp1_sqflite](exp1_sqflite) | `sqflite` plugin | Android, iOS, macOS |
| [exp1_sqflite_ffi](exp1_sqflite_ffi) | `sqflite_ffi` (SQLite bundled by `package:sqlite3`) | Android, iOS, macOS, Linux, Windows |
| [exp1_web](exp1_web) | `sqflite_common_ffi_web` (SQLite wasm in a shared worker, IndexedDB) | web |
| [exp1_app](exp1_app) | merged: the plugin when supported (Android, iOS, macOS), `sqflite_ffi` on Linux and Windows, `sqflite_common_ffi_web` on the web | all |
| [exp1_support](exp1_support) | scenario tool | host |

Each app is a `main.dart` choosing a `DatabaseFactory` and calling
`runExp1App()`. The common code never uses the global `databaseFactory`; the
factory is passed explicitly, so having both the `sqflite` and `sqflite_ffi`
plugins in the merged app is not a problem.

## Database

Two tables and two views ([exp1_schema.dart](exp1_common/lib/src/db/exp1_schema.dart)):

- `TodoList (id, name, created)`
- `Task (id, list_id → TodoList ON DELETE CASCADE, title, done, created)`
- `TodoListView`: lists with `task_count` and `done_count` (LEFT JOIN + GROUP BY)
- `TaskView`: tasks with their `list_name`

The views hold the joins and aggregates once, so the app code
([exp1_db.dart](exp1_common/lib/src/db/exp1_db.dart)) has no raw SQL:

- reads use `query()` on the views (`db.query('TodoListView', orderBy: ...)`);
- writes use `insert()`, `update()` and `delete()` on the tables. Deleting a
  list deletes its tasks (`PRAGMA foreign_keys = ON` in `onConfigure`).

## Run an app

Platform folders are not checked in. Create the ones you need, then run:

```bash
cd exp1_app
flutter create --org com.tekartik.exp1 --platforms linux,android,web .
# web only: SQLite wasm binary and the sqflite shared worker
dart run sqflite_common_ffi_web:setup
flutter run -d linux
```

The scenario tool does this for you (`flutter create` the first time, then
the web setup).

The lists page menu has two dev actions: *Reset demo database* and *Hold a
write transaction*. The second inserts a task in a transaction that never
ends, so the database stays locked until the app is hot restarted or
restarted.

## Scenario tool

```bash
cd exp1_support
# variants, scenarios and connected devices
dart run tool/scenario_run.dart --list
# all scenarios of the merged app on the host desktop
dart run tool/scenario_run.dart
# every variant supported by a device
dart run tool/scenario_run.dart -v all -d emulator-5554
# chosen scenarios, with the flutter run and app output
dart run tool/scenario_run.dart -v web -d chrome -s crud,restart --verbose
```

How it works:

- The app is launched in debug with `flutter run --machine -d <device>
  --dart-define=EXP1_DRIVER=true`. The daemon protocol (stdin/stdout JSON)
  gives the VM service uri, and handles hot restart (`app.restart`,
  `fullRestart`) and stop (`app.stop`).
- With `EXP1_DRIVER`, the app enables the flutter_driver extension
  ([exp1_setup.dart](exp1_common/lib/src/app/exp1_setup.dart)). The tool
  connects to the `main` isolate (the sqflite_ffi isolate is another one)
  and drives the UI through widget ids.
- Every widget used by a scenario is wrapped in `Exp1Id`
  ([exp1_id.dart](exp1_common/lib/src/ui/exp1_id.dart)). The id is a
  `ValueKey` (flutter_driver `find.byValueKey`) and a `Semantics.identifier`:
  the Android `resource-id` for uiautomator, `flt-semantics-identifier` on
  the web, `accessibilityIdentifier` on iOS. Ids are listed in
  [exp1_ids.dart](exp1_common/lib/src/exp1_ids.dart). That file is pure
  Dart, shared with the tool through `package:sqflite_exp1_common/exp1_shared.dart`.
- Checks read the database through `requestData('state')`: lists, counts
  from the views, and tasks, as JSON.
- On a failure, a screenshot is saved in `.local/scenario_failures/` (not on
  the web, where the driver has no screenshot).

Scenarios:

| Scenario | Steps | Checks |
|---|---|---|
| `crud` | reset, add a list, add two tasks, toggle one, delete the list | counts from the views, cascade delete |
| `hot-restart` | reset, add a list, hold a write transaction, hot restart | list kept, held task rolled back, database writable |
| `restart` | reset, add a list, hold a write transaction, stop and launch | list persisted, held task rolled back, database writable |

Gotchas found on the way:

- flutter_driver `find.pageBack()` and `find.byTooltip()` only match the
  `flutter/material` widgets, not the `material_ui` ones: the tasks page
  back button has its own id.
- On the web, IndexedDB is per origin, port included. The tool launches the
  web apps on a fixed port (`--web-port`, 8761 for web, 8764 for merged);
  with the default random port, the data is lost at each launch.
- The `app.debugPort` event comes after `app.started` on the web.

## Results

2026-10-22, Flutter 3.47.6, Linux host, Android emulator (API 36), Chrome:

| Variant | Device | crud | hot-restart | restart |
|---|---|---|---|---|
| sqflite | Android | PASS | PASS | PASS |
| sqflite_ffi | Android | PASS | PASS | PASS |
| sqflite_ffi | Linux | PASS | PASS | PASS |
| web | Chrome | PASS | **FAIL** | PASS |
| merged | Android (plugin) | PASS | PASS | PASS |
| merged | Linux (ffi) | PASS | PASS | PASS |
| merged | Chrome (web) | PASS | **FAIL** | PASS |

The hot restart releases the held transaction everywhere except on the web:

- **sqflite plugin:** the native connection survives the hot restart, and
  opening the single instance database again rolls back the active
  transaction (`rollbackActiveTransactionOnOpen`, on by default in debug).
- **sqflite_ffi:** the hot restart shuts down the isolate group, and the
  native finalizer of `package:sqlite3` closes the connection, which rolls
  back the transaction.
- **sqflite_common_ffi_web:** the shared worker outlives the page and keeps
  the transaction open. After the hot restart, opening the database never
  completes until every tab of the site is closed. A hot restart without an open
  transaction works, data included.
