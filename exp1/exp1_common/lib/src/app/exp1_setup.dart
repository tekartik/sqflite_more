import 'dart:convert';

import 'package:flutter_driver/driver_extension.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_exp1_common/src/db/exp1_db.dart';
import 'package:sqflite_exp1_common/src/ui/exp1_app.dart';

/// True when built with `--dart-define=EXP1_DRIVER=true` (scenario tool).
const exp1DriverEnabled = bool.fromEnvironment('EXP1_DRIVER');

/// How an exp1 app variant opens its database.
class Exp1Setup {
  /// Variant: `sqflite`, `sqflite_ffi`, `web` or `merged`.
  final String variant;

  /// Implementation used on this platform, shown in the app.
  final String implementation;

  /// Database factory, ready for relative database names.
  final DatabaseFactory databaseFactory;

  /// Setup of [variant].
  Exp1Setup({
    required this.variant,
    required this.implementation,
    required this.databaseFactory,
  });
}

Exp1Setup? _setup;
Exp1Db? _db;

/// To call first in `main()`, before any plugin call.
///
/// With `--dart-define=EXP1_DRIVER=true`, enables the flutter_driver
/// extension (it installs its own binding, text input is then emulated)
/// answering `requestData('state')` with the variant and the database
/// content. Otherwise initializes the regular binding.
void exp1EnsureInitialized() {
  if (exp1DriverEnabled) {
    enableFlutterDriverExtension(handler: _driverRequestData);
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
}

Future<String> _driverRequestData(String? message) async {
  if (message != 'state') {
    throw ArgumentError.value(message, 'message', 'unsupported');
  }
  var setup = _setup;
  var db = _db;
  var held = db?.transactionHeld ?? false;
  var info = {
    'variant': setup?.variant,
    'implementation': setup?.implementation,
    'held': held,
  };
  // The database is locked while the transaction is held, and closed for a
  // moment during a reset: the tool polls again.
  if (db == null || !db.isOpen || held) {
    return jsonEncode({...info, 'ready': db != null && held});
  }
  try {
    return jsonEncode({...info, 'ready': true, ...await db.state()});
  } catch (e) {
    return jsonEncode({...info, 'ready': false, 'error': '$e'});
  }
}

/// Opens the exp1 database with [setup] and runs the app.
Future<void> runExp1App(Exp1Setup setup) async {
  var db = Exp1Db(setup.databaseFactory);
  await db.open();
  _setup = setup;
  _db = db;
  runApp(Exp1App(setup: setup, db: db));
}
