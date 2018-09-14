import 'package:tekartik_common_utils/common_utils_import.dart';

// Get the server information
const methodGetServerInfo = 'sqfliteGetServerInfo';
// delete a database (param is map with 'path' key)
const methodDeleteDatabase = 'sqfliteDeleteDatabase';
// Create a directory if it does not exists (param is map with 'path' key, if null or relative, assumes getDatabasesPath)
const methodCreateDirectory = 'sqfliteCreateDirectory';
// Create a directory and its sub directory
const methodDeleteDirectory = 'sqfliteDeleteDirectory';
// Generic method to forward to sqlite (open, insert...)
const methodSqflite = 'sqfliteMethod';

const serverInfoName = 'sqflite_server';
final serverInfoVersion1 = Version(0, 5, 0);

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
const keySupportsWithoutRowId = 'supportsWithoutRowId';
