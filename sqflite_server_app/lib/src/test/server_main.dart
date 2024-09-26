import 'package:dev_build/menu/menu.dart';
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:sqflite_server_app/main.dart';

int defaultPort = sqfliteServerDefaultPort;

void main() {
  menu('server', () {
    SqfliteServer? server;
    item('start', () async {
      server ??= await SqfliteServer.serve(
          port: defaultPort, factory: databaseFactory!);
    });
    item('stop', () async {
      await server?.close();
      server = null;
    });
  });
}
