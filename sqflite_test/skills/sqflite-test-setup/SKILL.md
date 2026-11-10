---
name: sqflite-test-setup
description: >-
  Use when running the shared sqflite test suite from Flutter against a real
  device or a local factory with sqflite_test: testMain,
  SqfliteServerTestContext, SqfliteServerTestContext.connect,
  connectClientPort, SqfliteTestContext, SqfliteLocalTestContext,
  sqflite_common_test all_test.run, the sqflite_server_app + adb forward
  tcp:8501 setup, the SQFLITE_SERVER_URL / SQFLITE_SERVER_PORT defines, and
  databaseFactoryMock from package:sqflite_test/database_factory_mock.dart.
---

# Running the shared sqflite tests (sqflite_test)

`sqflite_test` is a test-only helper: it builds a `SqfliteTestContext` backed
by a **remote** sqflite implementation (the `sqflite_server_app` running on a
device, emulator or simulator) so the `sqflite_common_test` suites — and your
own tests — can exercise the real plugin from a `flutter test` run on the
host. It also re-exports `sqflite_common_test` and ships a no-op
`DatabaseFactoryMock`.

## Guidelines

* Dependency, in `dev_dependencies` (git only, this package is **not**
  published on pub.dev):
  ```yaml
  dev_dependencies:
    sqflite_test:
      git:
        url: https://github.com/tekartik/sqflite_more
        path: sqflite_test
      version: '>=0.2.0'
  ```
* Import `package:sqflite_test/sqflite_test.dart`. It re-exports everything
  from `package:sqflite_common_test/sqflite_test.dart` (`SqfliteTestContext`,
  `SqfliteTestContextMixin`, `SqfliteLocalTestContextMixin`,
  `SqfliteLocalTestContext`) and adds `SqfliteServerTestContext` and
  `testMain`. It does **not** export `test`/`expect`: import
  `package:flutter_test/flutter_test.dart` **or** `package:test/test.dart`,
  never both in the same file.
* `Future testMain(void Function(SqfliteServerTestContext context) run)` is
  the entry point: it connects to the server, calls `run(context)` with the
  connected context, and registers a `tearDownAll` that closes it. When no
  server answers it prints a hint and registers a single skipped test, so the
  file is green on a machine with no device. Write the callback as
  `void run(SqfliteTestContext context)` so it can be reused with any
  context.
* Running against a device:
  1. start the `sqflite_server_app` (`sqflite_more/sqflite_server_app`,
     `flutter run`) on the device/emulator and press START (or turn its auto
     start on);
  2. Android only: `adb forward tcp:8501 tcp:8501` — `connectClientPort()`
     (so `connect()` and `testMain`) runs it itself, `adb` from the `PATH`,
     unless `SQFLITE_SERVER_URL` / `SQFLITE_SERVER_PORT` is declared (then
     forward the port yourself); with an explicit `port:` it forwards that
     port. sqflite_test before 0.2.4 never ran it in the default flow;
  3. `flutter test` on the host.
* Override the target with the compile-time declarations
  `SQFLITE_SERVER_URL` / `SQFLITE_SERVER_PORT` (`sqfliteServerUrlEnvKey` /
  `sqfliteServerPortEnvKey`, passed with `--dart-define`), not with process
  environment variables. The default is `ws://localhost:8501`.
* `SqfliteServerTestContext`: `connect()` (static, returns `null` and prints a
  hint when unreachable), `connectClientPort({int? port})` (connects to an
  explicit port, or to the default/overridden url; returns the client already
  connected, if any), `close()` (closes and forgets the client: a closed
  context connects again), `url`, `envUrl`, `envPort` (set only by a call
  without `port:`, to the declaration or its default), plus the whole
  `SqfliteTestContext` surface:
  `databaseFactory`, `initDeleteDb(dbName)`, `createDirectory(path)`,
  `deleteDirectory(path)`, `writeFile(path, data)`, `isInMemoryPath(path)`,
  `pathContext`, `isAndroid` / `isIOS` / `isMacOS` / `isLinux` / `isWindows`.
* Capability flags to guard tests with: `supportsWithoutRowId` and
  `supportsDeadLock` are `false` and `strict` is `false` on the server
  context (the native implementation is lenient), unlike the ffi one.
  `isPlugin` is `false` too, even when the server serves the plugin: the
  plugin only checks of the shared suite do not run through it.
* `pathContext` is the host's (`SqfliteTestContextMixin`), not the server's:
  on a Windows host with an Android/iOS server, `initDeleteDb` joins the
  device path with a backslash (it still opens, under another file name).
  Build device paths with `package:path`'s `posix` there.
* Run the whole shared suite with `run(context)` (or `sqfliteTestGroup`) from
  `package:sqflite_common_test/all_test.dart`: it covers batches,
  transactions, types, exceptions, open/close, WAL and more, and it only
  needs a `SqfliteTestContext`.
* No device needed: build a `SqfliteLocalTestContext(databaseFactory: ...)`
  over `databaseFactoryFfi` (after `sqfliteFfiInit()`), or serve ffi locally
  with `SqfliteServer.serve(factory: databaseFactoryFfi)` from
  `package:sqflite_common_server/sqflite_server.dart` and connect a
  `SqfliteServerDatabaseFactory` to it, or a `SqfliteServerTestContext` with
  `connectClientPort(port: server.port)`: same suite, no device.
* Always `TestWidgetsFlutterBinding.ensureInitialized()` first in a
  `flutter test` file that touches the plugin or ffi.
* Convention in this repo: test files that require a running server are named
  `*_test_.dart` (trailing underscore) so `flutter test` does not pick them
  up automatically; run them explicitly.
* `package:sqflite_test/database_factory_mock.dart` exposes
  `DatabaseFactoryMock` and the `databaseFactoryMock` instance: every method
  throws `UnimplementedError` except `databaseExists` (false) and
  `deleteDatabase` (no-op). Use it only to satisfy a `DatabaseFactory`
  parameter in a test that never touches a database.
* `package:sqflite_test/page_cursor.dart` (`Cursor`, `CursorRow`) is
  deprecated and unimplemented: ignore it.
* `context.devSetDebugModeOn(true)` is deprecated; it only turns on request
  logging on the server context.

## Examples

### Run the whole shared suite against the server app

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_test/sqflite_test.dart';

// Start the sqflite_server_app first (and `adb forward tcp:8501 tcp:8501`).
Future main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  return testMain(run);
}

void run(SqfliteTestContext context) {
  group('common', () {
    all.run(context);
  });
}
```

### Same suite, no device: serve ffi in the test process

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:sqflite_common_test/all_test.dart' as all;
import 'package:sqflite_test/sqflite_test.dart';

Future main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  var server = await SqfliteServer.serve(factory: databaseFactoryFfi);
  var databaseFactory = await SqfliteServerDatabaseFactory.connect(server.url);
  var context = SqfliteLocalTestContext(databaseFactory: databaseFactory);

  tearDownAll(() async {
    await server.close();
  });

  test('simplest', () async {
    var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
  all.run(context);
}
```

### Your own tests on the device database

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_test/sqflite_test.dart';

Future main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  return testMain(run);
}

void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;

  test('open and insert', () async {
    // Deletes the db and creates its parent folder, on the server side.
    var path = await context.initDeleteDb('my_test.db');
    var db = await factory.openDatabase(path);
    try {
      await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
      await db.insert('Test', {'name': 'some name'});
      expect(await db.query('Test'), [
        {'id': 1, 'name': 'some name'},
      ]);
    } finally {
      await db.close();
    }
  });

  test('without rowid', () async {
    // The native implementation does not support it.
  }, skip: !context.supportsWithoutRowId);
}
```

### Connect to an explicit port by hand

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_test/sqflite_test.dart';

Future main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('connect on 8501', () async {
    var context = SqfliteServerTestContext();
    // null when nothing is listening (a hint is printed).
    var client = await context.connectClientPort(port: 8501);
    if (client != null) {
      expect(context.url, 'ws://localhost:8501');
    }
    await context.close();
  });
}
```

### A factory that must never be used

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_test/database_factory_mock.dart';

void main() {
  test('mock factory', () async {
    DatabaseFactory factory = databaseFactoryMock;
    expect(await factory.databaseExists('any'), isFalse);
    // Anything else throws UnimplementedError.
  });
}
```

## Common mistakes

* Importing both `package:flutter_test/flutter_test.dart` and
  `package:test/test.dart` in the same file (`test`/`expect` clash).
* Expecting `SQFLITE_SERVER_URL` to be read from the shell environment: it is
  a `--dart-define` compile-time declaration.
* On Android, `adb` not in the `PATH` of the test, or a declared
  `SQFLITE_SERVER_URL` / `SQFLITE_SERVER_PORT`: no automatic
  `adb forward`, run it yourself. Or forgetting to start the server from the
  `sqflite_server_app` menu (it does not start by itself the first time).
* Calling `SqfliteServerTestContext.connect()` and using the result without a
  null check: use `testMain` instead, which skips cleanly.
* Depending on `sqflite_test` from `dependencies` instead of
  `dev_dependencies`.
* Using `databaseFactoryMock` for anything real: `openDatabase` throws.
