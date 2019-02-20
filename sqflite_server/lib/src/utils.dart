import 'package:sqflite_server/src/constant.dart';

String getSqfliteServerUrl({int port}) {
  port ??= sqfliteServerDefaultPort;
  return 'ws://localhost:$port';
}
