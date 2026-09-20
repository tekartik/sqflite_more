---
name: sqflite-common-server-client
description: >-
  Use when driving a remote sqflite database over a web socket with
  sqflite_common_server: SqfliteServerDatabaseFactory.connect,
  initSqfliteServerDatabaseFactory, sqfliteServerContext, SqfliteServerContext,
  SqfliteClient.connect / sendRequest / invoke / serverInfo, SqfliteContext,
  the SQFLITE_SERVER_URL and SQFLITE_SERVER_PORT environment keys,
  getSqfliteServerUrl, sqfliteServerDefaultUrl, and the
  package:sqflite_common_server/sqflite.dart or sqflite_client.dart imports.
---

# Talking to a sqflite server (sqflite_common_server)

`SqfliteServerDatabaseFactory` is a normal `sqflite_common` `DatabaseFactory`
whose operations are forwarded over a JSON-RPC 2 web socket to a
`SqfliteServer` (see `../sqflite-common-server-serve/SKILL.md`). Once
connected, all the usual `openDatabase` / `query` / `batch` / `transaction`
code runs unchanged against the remote database, typically the real sqflite
plugin on a device or emulator.

## Guidelines

* Dependency (git only, this package is **not** published on pub.dev):
  ```yaml
  dependencies:
    sqflite_common_server:
      git:
        url: https://github.com/tekartik/sqflite_more
        path: sqflite_common_server
      version: '>=0.3.0'
  ```
* Import `package:sqflite_common_server/sqflite.dart` for the client side:
  it exports `SqfliteServerDatabaseFactory`, `SqfliteServerContext`,
  `sqfliteServerContext`, `initSqfliteServerDatabaseFactory()`,
  `sqfliteServerDefaultUrl`, `sqfliteServerUrlEnvKey`,
  `sqfliteServerPortEnvKey`, `parseSqfliteServerUrlPort()`,
  `getSqfliteServerUrl()` and `sqfliteServerDefaultPort`. Add
  `package:sqflite_common/sqlite_api.dart` for `Database`,
  `OpenDatabaseOptions`, `inMemoryDatabasePath`.
* `SqfliteServerDatabaseFactory.connect(String url, {WebSocketChannelClientFactory? webSocketChannelClientFactory})`
  is the direct way in: `url` is the server's `ws://host:port`
  (`getSqfliteServerUrl(port: 8501)` builds the localhost one). It throws if
  nothing is listening or if the server protocol version does not match.
  Always `await factory.close()` when done.
* `initSqfliteServerDatabaseFactory()` is the test-friendly variant: it reads
  the url from the compile-time declarations `SQFLITE_SERVER_URL` /
  `SQFLITE_SERVER_PORT` (set with `-D`/`--dart-define`, **not** from the
  process environment), defaults to `ws://localhost:8501`, and returns
  `null` after printing a hint instead of throwing when the server is not
  running. Guard your tests with `skip: factory == null` or an `if`, as the
  package's own tests do.
* The factory is a `DatabaseFactory`: `openDatabase(path, options: OpenDatabaseOptions(...))`,
  `deleteDatabase(path)`, `getDatabasesPath()`. Paths are resolved on the
  **server**: a relative path lands in the device's databases directory;
  absolute host paths are meaningless there.
* `SqfliteServerContext` (and the lazy global `sqfliteServerContext`)
  implements `SqfliteContext` from
  `package:sqflite_common_server/sqflite_context.dart`: `databaseFactory`,
  `createDirectory`, `deleteDirectory`, `readFile`, `writeFile`,
  `pathContext` (forced to posix) and the platform flags `isAndroid`,
  `isIOS`, `isMacOS`, `isLinux`, `isWindows`, `supportsWithoutRowId`. Use it
  to push a fixture database file to the device or to skip a test on a given
  platform. `SqfliteServerContext.connect(url)` builds a connected one;
  `context.close()` releases it.
* The platform getters and `supportsWithoutRowId` throw if the context has no
  client: connect first.
* Low level: `package:sqflite_common_server/sqflite_client.dart` exports
  `SqfliteClient` and `ServerInfo`. `SqfliteClient.connect(url)`,
  `client.serverInfo` (nullable `isAndroid`/`isIOS`/... flags),
  `client.sendRequest<T>(method, param)` for the server-specific methods,
  `client.invoke<T>(method, param)` for raw sqflite methods
  (`'openDatabase'`, `'query'`, ...), `client.close()`. Prefer the factory;
  use the client only for the file/directory helpers or for debugging.
* Blob values survive the round trip: the client converts the JSON lists back
  to `Uint8List` in query and batch results.
* Errors from the server come back as `SqfliteDatabaseException`, so
  `try`/`catch` in existing sqflite code keeps working.
* In unit tests without a real socket, pass
  `webSocketChannelFactoryMemory.client` (from
  `package:tekartik_web_socket_io/web_socket_io.dart`) as
  `webSocketChannelClientFactory`, with the matching `.server` given to
  `SqfliteServer.serve`.
* Android: the host can only reach the device server through
  `adb forward tcp:8501 tcp:8501`.

## Examples

### Connect to a running server and use it as a normal factory

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_server/sqflite.dart';

Future<void> main() async {
  var factory = await SqfliteServerDatabaseFactory.connect(
    getSqfliteServerUrl(port: sqfliteServerDefaultPort), // ws://localhost:8501
  );
  try {
    // Relative: resolved against the server getDatabasesPath().
    await factory.deleteDatabase('example.db');
    var db = await factory.openDatabase(
      'example.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT)');
        },
      ),
    );
    await db.insert('Test', {'name': 'some name'});
    print(await db.query('Test'));
    await db.close();
  } finally {
    await factory.close();
  }
}
```

### Test suite that skips when no server is running

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:test/test.dart';

Future<void> main() async {
  // null (with a printed hint) when no server answers on
  // SQFLITE_SERVER_URL / ws://localhost:8501
  var factory = await initSqfliteServerDatabaseFactory();

  tearDownAll(() async {
    await factory?.close();
  });

  group('client', () {
    test('in memory', () async {
      var db = await factory!.openDatabase(inMemoryDatabasePath);
      try {
        expect(await db.getVersion(), 0);
      } finally {
        await db.close();
      }
    });
  }, skip: factory == null);
}
```

### Push a file to the server and read it back

```dart
import 'package:sqflite_common_server/sqflite.dart';

Future<void> main() async {
  var context = await SqfliteServerContext.connect(sqfliteServerDefaultUrl);
  try {
    // Paths are relative to the server databases directory.
    await context.createDirectory('fixtures');
    var path = await context.writeFile('fixtures/data.bin', [1, 2, 3]);
    var content = await context.readFile(path);
    print('$path: $content (android: ${context.isAndroid})');

    // The same context also exposes a DatabaseFactory.
    var db = await context.databaseFactory.openDatabase('fixtures/test.db');
    await db.close();
  } finally {
    await context.close();
  }
}
```

### Low level client: server info and raw invoke

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_server/sqflite_client.dart';

Future<void> main() async {
  var client = await SqfliteClient.connect(getSqfliteServerUrl());
  try {
    var info = client.serverInfo;
    print('android: ${info.isAndroid} withoutRowId: ${info.supportsWithoutRowId}');

    var result = await client.invoke<Map>('openDatabase', {
      'path': inMemoryDatabasePath,
    });
    print('database id: ${result['id']}');
  } finally {
    await client.close();
  }
}
```

## Common mistakes

* Using a host absolute path: paths are resolved on the server side.
* Expecting `initSqfliteServerDatabaseFactory()` to read
  `SQFLITE_SERVER_URL` from the process environment: it is a compile-time
  declaration (`-D` / `--dart-define`).
* Not handling the `null` return of `initSqfliteServerDatabaseFactory()`.
* Reading `sqfliteServerContext.isAndroid` before connecting a client.
* Forgetting `adb forward` when the server runs on an Android device.
* Leaking the connection: `close()` the factory, context or client.
