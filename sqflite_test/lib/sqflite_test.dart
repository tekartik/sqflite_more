// ignore_for_file: avoid_print

/// Runs the shared sqflite tests (`sqflite_common_test`) and your own tests
/// from a `flutter test` on the host against a sqflite server: the
/// `sqflite_server_app` on a device ([SqfliteServerTestContext], [testMain]).
///
/// Re-exports `package:sqflite_common_test/sqflite_test.dart`
/// ([SqfliteTestContext], [SqfliteLocalTestContext]...).
library;

import 'dart:async';

import 'package:process_run/cmd_run.dart';
import 'package:process_run/which.dart';
import 'package:sqflite_common_server/sqflite.dart';
import 'package:sqflite_common_server/src/sqflite_client.dart'; // ignore: implementation_imports
import 'package:sqflite_common_test/sqflite_test.dart';
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:test/test.dart';

export 'package:sqflite_common_test/sqflite_test.dart';

/*
/// Test context for testing
abstract class SqfliteTestContext {
  DatabaseFactory get databaseFactory;

  // True if dead lock can be tested
  bool get supportsDeadLock;

  bool get supportsWithoutRowId;

  bool get strict;

  /// Delete an existing db, creates its parent folder
  Future<String> initDeleteDb(String dbName);

  /// Create a directory
  Future<String> createDirectory(String path);

  /// Delete a directory content
  Future<String> deleteDirectory(String path);

  Future<String> writeFile(String path, List<int> data);

  bool isInMemoryPath(String path);

  Context get pathContext;

  bool get isAndroid;

  bool get isIOS;

  Future devSetDebugModeOn(bool on);
}

mixin SqfliteLocalTestContextMixin implements SqfliteTestContext {
  @override
  Future<String> createDirectory(String path) async {
    path = await fixDirectoryPath(path);
    try {
      await Directory(path).create(recursive: true);
    } catch (_) {}
    return path;
  }

  @override
  Future<String> deleteDirectory(String path) async {
    path = await fixDirectoryPath(path);
    try {
      await Directory(path).delete(recursive: true);
    } catch (_) {}
    return path;
  }

  @override
  Future<String> writeFile(String path, List<int> data) async {
    var databasesPath = await createDirectory(null);
    path = pathContext.join(databasesPath, path);
    await File(path).writeAsBytes(data);
    return path;
  }

  Future<String> fixDirectoryPath(String path) async {
    if (path == null) {
      path = await databaseFactory.getDatabasesPath();
    } else {
      if (!isInMemoryPath(path) && isRelative(path)) {
        path = pathContext.join(await databaseFactory.getDatabasesPath(), path);
      }
    }
    return path;
  }

  @override
  bool get isAndroid => Platform.isAndroid;

  @override
  bool get isIOS => Platform.isIOS;
}
mixin SqfliteTestContextMixin implements SqfliteTestContext {
  /// FFI no supports Without row id on linux
  @override
  bool get supportsWithoutRowId => false;

  @override
  bool get supportsDeadLock => false;

  /// FFI implementation is strict
  @override
  bool get strict => true;

  @override
  path.Context get pathContext => path.context;

  @override
  bool isInMemoryPath(String path) {
    return path == inMemoryDatabasePath;
  }

  @override
  Future<String> initDeleteDb(String dbName) async {
    var databasesPath = await createDirectory(null);
    // print(databasePath);
    var path = pathContext.join(databasesPath, dbName);
    await this.databaseFactory.deleteDatabase(path);
    return path;
  }
}

class SqfliteLocalTestContext
    with SqfliteTestContextMixin, SqfliteLocalTestContextMixin {
  @override
  DatabaseFactory get databaseFactory => sqflite.databaseFactory;

  @override
  Future devSetDebugModeOn(bool on) =>
      // ignore: deprecated_member_use
      sqflite.Sqflite.devSetDebugModeOn(on);
}

 */

/// A [SqfliteTestContext] whose databases live in a remote sqflite server:
/// the `sqflite_server_app` on a device, emulator or simulator, or a
/// `SqfliteServer` of `sqflite_common_server` started by the test.
///
/// Get one with [testMain] or [connect] (default url), or create one and call
/// [connectClientPort]. Its [databaseFactory] runs every call on the server.
///
/// Paths: [pathContext] is the context of the host running the test (from
/// [SqfliteTestContextMixin]), right for a posix server on a posix host.
class SqfliteServerTestContext extends SqfliteServerContext
    with SqfliteTestContextMixin
    implements SqfliteTestContext {
  /// The `SQFLITE_SERVER_URL` declaration, or the default url; set by
  /// [connectClientPort] when called without a port.
  String? envUrl;

  /// The `SQFLITE_SERVER_PORT` declaration, or 8501; set by
  /// [connectClientPort] when called without a port.
  int? envPort;

  /// The url of the server, set by [connectClientPort].
  late String url;

  @override
  bool get supportsWithoutRowId => false;

  /// Connects to the server on [port], or to the url/port of the
  /// `SQFLITE_SERVER_URL` / `SQFLITE_SERVER_PORT` compile-time declarations
  /// (`--dart-define`), `ws://localhost:8501` by default.
  ///
  /// Unless one of these declarations is given, it first tries
  /// `adb forward tcp:<port> tcp:<port>` (Android device or emulator).
  ///
  /// Returns null, after printing a hint, when no server answers.
  Future<SqfliteClient?> connectClientPort({int? port}) async {
    if (client == null) {
      // envUrl and envPort always get a value (their default when not
      // declared): test the declarations themselves.
      var envOverride = false;
      if (port != null) {
        url = getSqfliteServerUrl(port: port);
      } else {
        envOverride =
            const bool.hasEnvironment(sqfliteServerUrlEnvKey) ||
            const bool.hasEnvironment(sqfliteServerPortEnvKey);
        envPort = parseInt(
          String.fromEnvironment(
            sqfliteServerPortEnvKey,
            defaultValue: sqfliteServerDefaultPort.toString(),
          ),
        );
        envUrl = String.fromEnvironment(
          sqfliteServerUrlEnvKey,
          defaultValue: getSqfliteServerUrl(port: envPort),
        );
        url = envUrl!;
      }

      port ??= parseSqfliteServerUrlPort(url, defaultValue: 0);

      // Run the needed adb command if no env overrides
      if (!envOverride) {
        try {
          await runCmd(
            ProcessCmd(whichSync('adb')!, ['forward', 'tcp:$port', 'tcp:$port'])
              ..runInShell = true,
          );
        } catch (_) {}
      }

      try {
        await connectClient(url);
      } catch (e) {
        print(e);
      }
      if (client == null) {
        print('''
sqflite server not running on $url
Check that the sqflite_server_app is running on the proper port on a connected
iOS device/simulator, Android device/emulator

Android: 
  check that you have forwarded tcp ip on Android
  \$ adb forward tcp:$port tcp:$port

''');
        if (port == null) {
          print('''
url/port can be overriden using env variables
$sqfliteServerUrlEnvKey: ${envUrl ?? ''}
$sqfliteServerPortEnvKey: ${envPort ?? ''}

''');
        }
      }
    }
    return client;
  }

  /// Creates a context and connects it with [connectClientPort] (default
  /// url, `adb forward` first).
  ///
  /// Returns null, after printing a hint, when no server answers.
  static Future<SqfliteServerTestContext?> connect() async {
    var context = SqfliteServerTestContext();
    var sqfliteClient = await context.connectClientPort();
    if (sqfliteClient == null) {
      var url = context.url;
      var port = parseSqfliteServerUrlPort(url);
      print('''
sqflite server not running on $url
Check that the sqflite_server_app is running on the proper port
Android: 
  check that you have forwarded tcp ip on Android
  \$ adb forward tcp:$port tcp:$port

''');
    } else {
      return context;
    }
    return null;
  }

  // close(): the base one closes the client and forgets it, so that
  // connectClientPort() connects again.

  @override
  Future<T> sendRequest<T>(String method, Object? param) async {
    if (_debugModeOn) {
      print('$param');
    }
    var t = await super.sendRequest<T>(method, param);
    if (_debugModeOn) {
      print(t);
    }
    return t;
  }

  @override
  Future<T> invoke<T>(String method, Object? param) async {
    var t = await super.invoke<T>(method, param);
    return t;
  }

  bool _debugModeOn = false;

  @override
  @Deprecated('Deb only')
  Future devSetDebugModeOn(bool on) async {
    _debugModeOn = on;
  }

  /// Complex manual dead lock (multi instance) is not well supported. Avoid it
  @override
  bool get supportsDeadLock => false;

  @override
  /// Default implementation is not strict, ffi one is
  bool get strict => false;
}

/// Main entry point of a test file running on the sqflite server.
///
/// Connects with [SqfliteServerTestContext.connect], then calls [run] to
/// declare the tests and closes the context after them. When no server
/// answers, it declares a single skipped test instead: the file passes on a
/// machine with no device.
///
/// ```dart
/// Future main() {
///   TestWidgetsFlutterBinding.ensureInitialized();
///   return testMain(run);
/// }
///
/// void run(SqfliteTestContext context) {
///   all.run(context); // package:sqflite_common_test/all_test.dart
/// }
/// ```
Future testMain(void Function(SqfliteServerTestContext context) run) async {
  var context = await SqfliteServerTestContext.connect();
  if (context == null) {
    test('connected', () {}, skip: true);
  } else {
    run(context);
  }
  tearDownAll(() async {
    await context?.close();
  });
}

// void run(SqfliteServerTestContext context) {
