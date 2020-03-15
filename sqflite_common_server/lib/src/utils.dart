import 'package:sqflite_common_server/src/constant.dart';

String getSqfliteServerUrl({int port}) {
  port ??= sqfliteServerDefaultPort;
  return 'ws://localhost:$port';
}
