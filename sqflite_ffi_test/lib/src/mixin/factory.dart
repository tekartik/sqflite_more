import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite/src/factory_mixin.dart';

/// Mixin handler
abstract class SqfliteFfiInvokeHandler {
  Future<T> invokeMethod<T>(String method, [dynamic arguments]);
}

// TO IMPLEMENT IN SQFLITE
class _SqfliteDatabaseFactoryImpl
    with SqfliteDatabaseFactoryMixin
    implements SqfliteFfiInvokeHandler {
  _SqfliteDatabaseFactoryImpl(this._invokeMethod);

  final Future<dynamic> Function(String method, [dynamic arguments])
      _invokeMethod;

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) async =>
      (await _invokeMethod(method, arguments)) as T;
}

/// Build a database factory invoking the invoke method instead of going through
/// flutter services.
///
/// To use to enable running without flutter plugins (unit test)
DatabaseFactory buildDatabaseFactory(
    {Future<dynamic> Function(String method, [dynamic arguments])
        invokeMethod}) {
  final DatabaseFactory impl = _SqfliteDatabaseFactoryImpl(invokeMethod);
  return impl;
}
