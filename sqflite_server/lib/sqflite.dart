export 'src/factory.dart' show SqfliteServerDatabaseFactory;
import 'dart:async';

import 'package:sqflite_server/sqflite.dart';

const sqfliteServerUrlEnvKey = 'SQFLITE_SERVER_URL';
const sqfliteServerDefaultPort = 8501;
const sqfliteServerDefaultUrl = 'ws://localhost:$sqfliteServerDefaultPort';

Future<SqfliteServerDatabaseFactory> initSqfliteServerDatabaseFactory() async {
  SqfliteServerDatabaseFactory databaseFactory;
  var url = String.fromEnvironment(sqfliteServerUrlEnvKey,
      defaultValue: sqfliteServerDefaultUrl);
  try {
    databaseFactory = await SqfliteServerDatabaseFactory.connect(url);
  } catch (e) {
    print(e);
  }
  if (databaseFactory == null) {
    print(
        'sqflite server not running on $url or missing SQFLITE_SERVER_URL env variable');
  }
  return databaseFactory;
}
