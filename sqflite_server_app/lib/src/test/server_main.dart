import 'package:sqflite_server_app/main.dart';
import 'package:tekartik_test_menu/test.dart';
import 'package:sqflite_common_server/sqflite_server.dart';

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
