---
name: sqflite-common-server-serve
description: >-
  Use when exposing a sqflite DatabaseFactory over a web socket (JSON-RPC 2)
  with sqflite_common_server: SqfliteServer.serve, SqfliteServerNotifyCallback,
  server.url / server.port, sqfliteServerDefaultPort, getSqfliteServerUrl, the
  package:sqflite_common_server/sqflite_server.dart import, running a
  sqflite_server_app on a device or emulator, adb port forwarding, or serving
  databaseFactoryFfi in tests over a memory web socket.
---

# Serving a database (sqflite_common_server)

`sqflite_common_server` wraps any `sqflite_common` `DatabaseFactory` in a
JSON-RPC 2 web socket server, so another isolate, process or machine can drive
that database remotely. The typical use is the `sqflite_server_app`: a Flutter
app running on a device that serves its real sqflite plugin implementation to
tests running on the host. See `../sqflite-common-server-client/SKILL.md` for
the client side.

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
* Import `package:sqflite_common_server/sqflite_server.dart`. It exports
  `SqfliteServer`, the `SqfliteServerNotifyCallback` typedef,
  `sqfliteServerDefaultPort` (8501) and `getSqfliteServerUrl({int? port})`
  (`ws://localhost:<port>`). It does **not** re-export `sqflite_common`: add
  `package:sqflite_common/sqlite_api.dart` for `DatabaseFactory`.
* `SqfliteServer.serve({required DatabaseFactory factory, Object? address, int? port, SqfliteServerNotifyCallback? notifyCallback, WebSocketChannelServerFactory? webSocketChannelServerFactory})`
  returns the running server. `server.url` is the `ws://` url to hand to a
  client, `server.port` the effective port, `server.close()` stops it.
* `factory` must be a real sqflite implementation factory
  (`databaseFactoryFfi`, or `databaseFactory` from the `sqflite` Flutter
  plugin). It is cast to `SqfliteInvokeHandler` internally, so a hand-written
  `DatabaseFactory` that is not built on the sqflite mixins will fail at
  runtime.
* Omit `port` to bind a free port (read `server.port` / `server.url`
  afterwards); pass `port: sqfliteServerDefaultPort` for the well-known 8501
  that clients probe by default.
* `webSocketChannelServerFactory` defaults to `webSocketChannelServerFactoryIo`
  (real sockets, needs `dart:io`). In a unit test, pass
  `webSocketChannelFactoryMemory.server` from
  `package:tekartik_web_socket_io/web_socket_io.dart` (it re-exports the
  memory factories) and give the matching `.client` to the client: no real
  socket, no port conflict.
* `notifyCallback(bool response, String method, Object? params)` is called
  twice per request (once with `response: false` for the incoming call, once
  with `true` for the result). It is the hook used by `sqflite_server_app` to
  log traffic in its UI; keep it cheap, it runs on every sqflite operation.
* One `SqfliteServerChannel` is created per connected client and it tracks the
  databases that client opened: when the connection drops, those databases are
  closed automatically. `server.close()` closes the web socket server, not the
  factory.
* Paths are resolved server side: a relative path is joined with the server's
  `getDatabasesPath()`, `inMemoryDatabasePath` is passed through. Clients also
  get `sqfliteCreateDirectory` / `sqfliteDeleteDirectory` /
  `sqfliteWriteFile` / `sqfliteReadFile` helpers rooted the same way, so a
  client can prepare fixture files on the device.
* Android device: forward the port before connecting from the host, e.g.
  `adb forward tcp:8501 tcp:8501`.
* There is no authentication and no TLS. Serve on localhost / a forwarded
  port on a development machine only, never on a public interface.
* The client checks the protocol version (`sqflite_server` 0.5.0) at connect
  time and throws a `StateError` on mismatch: keep both sides on the same
  `sqflite_common_server` version.

## Examples

### Serve an ffi database on the default port

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite_server.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var server = await SqfliteServer.serve(
    port: sqfliteServerDefaultPort,
    factory: databaseFactoryFfi,
  );
  print('serving on ${server.url}'); // ws://localhost:8501
  // await server.close();
}
```

### Log every request with a notify callback

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_server/sqflite_server.dart';

Future<SqfliteServer> serveVerbose(DatabaseFactory factory) async {
  return await SqfliteServer.serve(
    factory: factory,
    // port omitted: a free port is picked, read server.port.
    notifyCallback: (response, method, params) {
      print('${response ? '<-' : '->'} $method $params');
    },
  );
}
```

### Server and client in the same test, over a memory web socket

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:test/test.dart';

void main() {
  sqfliteFfiInit();

  test('serve and connect', () async {
    WebSocketChannelFactory channelFactory = webSocketChannelFactoryMemory;
    var server = await SqfliteServer.serve(
      webSocketChannelServerFactory: channelFactory.server,
      factory: databaseFactoryFfi,
    );
    var databaseFactory = await SqfliteServerDatabaseFactory.connect(
      server.url,
      webSocketChannelClientFactory: channelFactory.client,
    );
    var db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();

    await databaseFactory.close();
    await server.close();
  });
}
```

### Serve the real sqflite plugin from a Flutter app

In the Flutter app, `factory` is the `databaseFactory` getter from
`package:sqflite/sqflite.dart` (added as a dependency of that app, not of this
package), after `WidgetsFlutterBinding.ensureInitialized()`. The plumbing is
the same everywhere:

```dart
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_server/sqflite_server.dart';

/// [factory] is `databaseFactory` from package:sqflite in a Flutter app.
/// On Android also run `adb forward tcp:8501 tcp:8501` on the host.
Future<SqfliteServer> startDeviceServer(DatabaseFactory factory) async {
  return await SqfliteServer.serve(
    port: sqfliteServerDefaultPort,
    factory: factory,
  );
}
```

## Common mistakes

* Passing a `DatabaseFactory` that is not a sqflite implementation (it must
  also be a `SqfliteInvokeHandler`).
* Forgetting `sqfliteFfiInit()` before `databaseFactoryFfi`.
* Using the io server factory in a unit test instead of
  `webSocketChannelFactoryMemory.server`, and then mixing it with a client
  connected through the io factory.
* Expecting `server.close()` to also close the databases opened by clients
  that are still connected.
* Exposing the server beyond localhost: there is no auth.
