# sqflite_exp1_common

Common code of the sqflite exp1 apps: a todo lists and tasks database
(tables, views, `Exp1Db`), its Flutter UI and the hooks of the scenario tool.
Each exp1 app only chooses a `DatabaseFactory` and calls `runExp1App()`. See
the [exp1 README](../README.md) for the apps, the database and the scenario
tool.

Not on pub.dev (`publish_to: none`), a member of the sqflite_more workspace.

## Usage

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_exp1_common/sqflite_exp1_common.dart';

/// Exp1 on the ffi factory (desktop).
Future<void> main() async {
  exp1EnsureInitialized();
  sqfliteFfiInit();
  await runExp1App(
    Exp1Setup(
      variant: 'ffi',
      implementation: 'sqflite_common_ffi',
      databaseFactory: databaseFactoryFfi,
    ),
  );
}
```

The database name `exp1.db` is relative: it goes in the databases path of
the factory (set it with `setDatabasesPath()` where the default is not
writable, as `exp1_sqflite_ffi` does on mobile). `exp1EnsureInitialized()`
enables the flutter_driver extension when built with
`--dart-define=EXP1_DRIVER=true` (scenario tool).

`Exp1Db` works without the UI, on any factory:

```dart
var db = Exp1Db(databaseFactoryFfi, name: inMemoryDatabasePath);
await db.open(); // creates the schema and the demo lists
print((await db.getLists()).map((list) => list.name)); // (Groceries, Work)
await db.close();
```

## Tests

```bash
flutter test
```
