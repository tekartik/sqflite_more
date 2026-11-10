# sqflite_common_server

Drive a sqflite database remotely: `SqfliteServer` serves any sqflite
`DatabaseFactory` (the sqflite plugin in an app on a device, `sqflite_common_ffi`
on a desktop) over a web socket (JSON-RPC 2), and
`SqfliteServerDatabaseFactory` is a regular `DatabaseFactory` whose calls run
on that server.

The typical use: run [sqflite_server_app](../sqflite_server_app) on a device
or an emulator, and run unit tests on the host against the real sqflite
plugin of that device (see [sqflite_test](../sqflite_test)).

## Getting started

Git dependency (not published on pub.dev):

```yaml
dependencies:
  sqflite_common_server:
    git:
      url: https://github.com/tekartik/sqflite_more
      path: sqflite_common_server
```

A server and a client in the same process, over a memory web socket
([example/main.dart](example/main.dart), `sqflite_common_ffi` for the served
implementation):

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var channelFactory = webSocketChannelFactoryMemory;

  // Server side: any sqflite implementation factory.
  var server = await SqfliteServer.serve(
    factory: databaseFactoryFfi,
    webSocketChannelServerFactory: channelFactory.server,
  );

  // Client side: a regular sqflite DatabaseFactory.
  var factory = await SqfliteServerDatabaseFactory.connect(
    server.url,
    webSocketChannelClientFactory: channelFactory.client,
  );
  try {
    var db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE Todo (id INTEGER PRIMARY KEY, title TEXT)',
          );
        },
      ),
    );
    await db.insert('Todo', {'title': 'Buy milk'});
    print(await db.query('Todo')); // [{id: 1, title: Buy milk}]
    await db.close();
  } finally {
    await factory.close();
    await server.close();
  }
}
```

Without the `webSocketChannel*Factory` arguments, the server listens on a real
web socket (`port: 8501` = `sqfliteServerDefaultPort`, a free port when
omitted) and the client connects to its `ws://` url.

Platforms (`dart:io` web sockets, not the web): the client runs on the Dart
VM and Flutter on Android, iOS, macOS, Linux and Windows; the server on
Android, iOS, macOS and Linux (the client resolves paths with posix rules: a
Windows server is not supported).

## When to use what

| API | Import | Use |
|---|---|---|
| `SqfliteServer.serve(factory: ...)` | `sqflite_server.dart` | serve a sqflite implementation factory (it must be built on the sqflite mixins: the plugin `databaseFactory`, `databaseFactoryFfi`...) |
| `SqfliteServerDatabaseFactory.connect(url)` | `sqflite.dart` | the client `DatabaseFactory`: `openDatabase`, `deleteDatabase`, transactions, batches, cursors, `readDatabaseBytes`... run on the server |
| `initSqfliteServerDatabaseFactory()` | `sqflite.dart` | tests: connects to `SQFLITE_SERVER_URL` / `SQFLITE_SERVER_PORT` (compile-time `--dart-define`, default `ws://localhost:8501`), `null` when no server answers |
| `SqfliteServerContext` | `sqflite.dart` | the factory plus file helpers on the server (`createDirectory`, `writeFile`, `readFile`...) and its platform (`isAndroid`, `isIOS`...) |
| `SqfliteClient` | `sqflite_client.dart` | low level JSON-RPC client (server info, raw sqflite methods) |

## Server on an Android device

```bash
# Start sqflite_server_app on the device, then forward its port
adb forward tcp:8501 tcp:8501
# The host tests connect to ws://localhost:8501
```

## Pitfalls

* Relative database paths resolve in the databases path the **server**
  implementation returns (`getDatabasesPath()` through the protocol). A
  `setDatabasesPath()` on the served factory is not seen by the clients, but
  is used by the file helpers (`SqfliteServerContext.writeFile`...): do not
  call it on a served factory.
* Values cross as JSON: blobs come back as `Uint8List` (query, batch and
  `readDatabaseBytes` results), but a non finite REAL (`Infinity`,
  `-Infinity`, `NaN`) cannot be encoded: the call never completes and the
  connection stops answering.
* `server.close()` closes the connected clients; the databases each client
  left open are closed right after (not awaited).
* No authentication, no TLS: serve on localhost or a forwarded port of a
  development machine only.
* The client refuses a server older than its protocol version (0.5.0): keep
  both sides on the same package version.
