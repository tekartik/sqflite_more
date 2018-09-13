import 'package:tekartik_common_utils/common_utils_import.dart';

// Get the server information
const methodGetServerInfo = 'sqfliteGetServerInfo';
// delete a database (param is map with 'path' key)
const methodDeleteDatabase = 'sqfliteDeleteDatabase';
// Generic method to forward to sqlite (open, insert...)
const methodSqflite = 'sqfliteMethod';

const serverInfoName = 'sqflite_server';
final serverInfoVersion1 = Version(0, 1, 0);

// server version
final serverInfoVersion = serverInfoVersion1;

// Min version expected by the client
final serverInfoMinVersion = serverInfoVersion1;

const keyMethod = 'method';
const keyParam = 'param';

// delete database
const keyPath = 'path';

// server info
const keyName = 'name';
const keyVersion = 'version';
