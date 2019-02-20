import 'package:tekartik_common_utils/common_utils_import.dart';

// Get the server information
const methodGetServerInfo = 'sqfliteGetServerInfo';
// delete a database (param is map with 'path' key)
const methodDeleteDatabase = 'sqfliteDeleteDatabase';
// Create a directory if it does not exists (param is map with 'path' key, if null or relative, assumes getDatabasesPath)
const methodCreateDirectory = 'sqfliteCreateDirectory';
// Create a directory and its sub directory
const methodDeleteDirectory = 'sqfliteDeleteDirectory';

// Write a file (Unit8List)
const methodWriteFile = 'sqfliteWriteFile';
// Read a file (Unit8List)
const methodReadFile = 'sqfliteReadFile';

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
// binary content (unoptimized List<int>)
const keyContent = 'content';

// server info
const keyName = 'name';
const keyVersion = 'version';
const keySupportsWithoutRowId = 'supportsWithoutRowId';
const keyIsIOS = 'isIOS';
const keyIsAndroid = 'isAndroid';

const sqfliteServerDefaultPort = 8501;
