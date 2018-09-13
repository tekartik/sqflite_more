import 'package:sqflite_server/sqflite_server.dart';
import 'package:sqflite_server_app/src/prefs.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

class App {
  bool started = false;
  Prefs prefs;
  SqfliteServer _sqfliteServer;
  SqfliteServer get sqfliteServer => _sqfliteServer;

  bool get sqfliteServerStarted => _sqfliteServer != null;

  Future<SqfliteServer> startServer(int port) async {
    await _closeServer();
    _sqfliteServer = await SqfliteServer.serve(port: port);
    return _sqfliteServer;
  }

  Future stopServer() => _closeServer();

  Future _closeServer() async {
    if (_sqfliteServer != null) {
      var done = _sqfliteServer.close();
      _sqfliteServer = null;
      await done;
    }
  }
}

App _app;
App get app => _app ??= App();

Future clearApp() async {
  //_app = null;
  await app.stopServer();
  var prefs = Prefs();
  await prefs.load();
  app.prefs = prefs;
  app.started = false;
}
