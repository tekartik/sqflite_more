import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

abstract class SqfliteContext {
  DatabaseFactory get databaseFactory;
}

class _SqfliteContext implements SqfliteContext {
  @override
  DatabaseFactory get databaseFactory => sqflite.databaseFactory;
}

SqfliteContext _sqfliteContext;
SqfliteContext get sqfliteContext => _sqfliteContext ??= _SqfliteContext();
