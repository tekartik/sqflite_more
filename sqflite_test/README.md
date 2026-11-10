# sqflite_test

Run sqflite tests from a `flutter test` on your computer against the real
sqflite plugin of a device: the databases live in the
[`sqflite_server_app`](../sqflite_server_app) (this repository), the test
talks to it over a web socket. Run the shared sqflite test suite
(`sqflite_common_test`) or your own tests this way.

Test helper only, git package (not on pub.dev).

## Getting started

Add it to your `dev_dependencies`:

```yaml
dev_dependencies:
  sqflite_test:
    git:
      url: https://github.com/tekartik/sqflite_more
      path: sqflite_test
```

A test file, `test/device_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_test/sqflite_test.dart';

Future main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Connects to the server, then declares the tests of run().
  return testMain(run);
}

void run(SqfliteTestContext context) {
  var factory = context.databaseFactory;

  test('open and insert', () async {
    // Deletes the database on the server and creates its folder.
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
}
```

Run it:

1. Start the server: `flutter run` the
   [`sqflite_server_app`](../sqflite_server_app) on the device or emulator
   and press START (or turn auto start on).
2. On your computer: `flutter test test/device_test.dart`.

Android: `testMain` first runs `adb forward tcp:8501 tcp:8501` (`adb` must be
in your `PATH`). When no server answers, a hint is printed and the file
passes with a single skipped test: the same file can stay in a CI with no
device.

The whole shared suite: `run(context)` of
`package:sqflite_common_test/all_test.dart` (in `dev_dependencies` too).

## Platforms

* The test runs on the host Dart VM (`flutter test` on Linux, macOS or
  Windows), not on the web.
* The server: the `sqflite_server_app` (Android is the tested target), or a
  `SqfliteServer` started by the test itself (below).

## Another port, no device

* Another url or port: `flutter test --dart-define=SQFLITE_SERVER_PORT=8502`
  (or `SQFLITE_SERVER_URL=ws://<host>:<port>`). These are compile-time
  declarations, not environment variables. With one of them, `adb forward`
  is not run: forward the port yourself.
* No device: serve `databaseFactoryFfi` from the test and connect to it
  (`sqflite_common_ffi` and `sqflite_common_server`, the git package of this
  repository, in your `dev_dependencies` too):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:sqflite_test/sqflite_test.dart';

Future main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  // A free port.
  var server = await SqfliteServer.serve(factory: databaseFactoryFfi);
  var context = SqfliteServerTestContext();
  await context.connectClientPort(port: server.port);
  tearDownAll(() async {
    await context.close();
    await server.close();
  });

  test('version', () async {
    var db = await context.databaseFactory.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
}
```

## Pitfalls

* Import `package:flutter_test/flutter_test.dart` or `package:test/test.dart`,
  not both (`test`, `expect` clash).
* Start the server from the app menu first; on Android the port forward only
  works with `adb` in your `PATH`.
* In this repository, test files needing a running server end with
  `_test_.dart` so that a plain `flutter test` skips them: run them by name.
* `context.pathContext` is the path context of your computer: on a Windows
  computer with an Android device, `initDeleteDb` joins the device path with
  a backslash (the database opens, under another file name).
* `context.isPlugin` is false: the plugin only checks of the shared suite are
  not run through the server.
* `package:sqflite_test/database_factory_mock.dart` (`databaseFactoryMock`)
  only satisfies a `DatabaseFactory` parameter: `openDatabase` throws.

More in the [skill](skills/sqflite-test-setup/SKILL.md).
