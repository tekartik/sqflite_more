import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:sqflite_server_app/main.dart';
import 'package:sqflite_server_app/src/prefs.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

Version _appVersion = Version(0, 1, 0);

class App {
  bool started = false;
  Prefs? prefs;
  SqfliteServer? _sqfliteServer;

  SqfliteServer? get sqfliteServer => _sqfliteServer;

  bool get sqfliteServerStarted => _sqfliteServer != null;

  Version get version => _appVersion;

  Future<SqfliteServer?> startServer(int? port,
      {SqfliteServerNotifyCallback? notifyCallback}) async {
    await _closeServer();
    _sqfliteServer = await SqfliteServer.serve(
        port: port, notifyCallback: notifyCallback, factory: databaseFactory!);
    return _sqfliteServer;
  }

  Future stopServer() => _closeServer();

  Future _closeServer() async {
    if (_sqfliteServer != null) {
      var done = _sqfliteServer!.close();
      _sqfliteServer = null;
      await done;
    }
  }
}

App? _app;

App get app => _app ??= App();

Future clearApp() async {
  //_app = null;
  await app.stopServer();
  var prefs = Prefs(databaseFactory: databaseFactory);
  await prefs.load();
  app.prefs = prefs;
  app.started = false;
}
