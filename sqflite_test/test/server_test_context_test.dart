@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_server/sqflite.dart'
    show sqfliteServerPortEnvKey, sqfliteServerUrlEnvKey;
import 'package:sqflite_common_server/sqflite_server.dart';
import 'package:sqflite_test/sqflite_test.dart';

void main() {
  group('SqfliteServerTestContext', () {
    test('connect, close and connect again', () async {
      sqfliteFfiInit();
      // A local server on a free port, serving ffi.
      var server = await SqfliteServer.serve(factory: databaseFactoryFfi);
      try {
        var context = SqfliteServerTestContext();
        expect(await context.connectClientPort(port: server.port), isNotNull);
        await context.close();
        expect(context.client, isNull);

        // A closed context connects again.
        expect(await context.connectClientPort(port: server.port), isNotNull);
        var db = await context.databaseFactory.openDatabase(
          inMemoryDatabasePath,
        );
        expect(await db.getVersion(), 0);
        await db.close();
        await context.close();
      } finally {
        await server.close();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test(
      'connectClientPort() forwards the default port with adb',
      () async {
        // A fake adb, first in the paths process_run looks in.
        var dir = await Directory.systemTemp.createTemp('sqflite_test_adb');
        try {
          var log = File(join(dir.path, 'adb.log'));
          await File(
            join(dir.path, 'adb'),
          ).writeAsString('#!/bin/sh\necho "\$@" >> "${log.path}"\n');
          await runExecutableArguments('chmod', ['+x', join(dir.path, 'adb')]);
          shellEnvironment = ShellEnvironment()..paths.prepend(dir.path);

          var context = SqfliteServerTestContext();
          // Whether a server answers on 8501 or not does not matter here.
          await context.connectClientPort();
          await context.close();
          expect(log.existsSync(), isTrue, reason: 'adb not run');
          expect(
            await log.readAsString(),
            contains('forward tcp:8501 tcp:8501'),
          );
        } finally {
          shellEnvironment = null;
          await dir.delete(recursive: true);
        }
      },
      skip:
          Platform.isWindows ||
              const bool.hasEnvironment(sqfliteServerUrlEnvKey) ||
              const bool.hasEnvironment(sqfliteServerPortEnvKey)
          ? 'needs sh and no SQFLITE_SERVER_URL/PORT declaration'
          : null,
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
