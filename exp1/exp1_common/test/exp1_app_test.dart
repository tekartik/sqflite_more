@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_exp1_common/sqflite_exp1_common.dart';

void main() {
  late Directory dir;
  late Exp1Db db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('exp1_app_');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });

  /// Lets the real database calls complete, then rebuilds.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }
  }

  testWidgets('lists, tasks and ids', (tester) async {
    await tester.runAsync(() async {
      db = Exp1Db(
        databaseFactoryFfiNoIsolate,
        name: join(dir.path, exp1DbName),
      );
      await db.open();
    });
    var setup = Exp1Setup(
      variant: 'test',
      implementation: 'sqflite_common_ffi (no isolate)',
      databaseFactory: databaseFactoryFfiNoIsolate,
    );
    await tester.pumpWidget(Exp1App(setup: setup, db: db));
    await settle(tester);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('3 tasks, 1 done'), findsOneWidget);

    // Ids are keys and semantics identifiers
    var groceries = (await tester.runAsync(db.getLists))!.first;
    var listFinder = find.byKey(ValueKey(Exp1Ids.list(groceries.id)));
    expect(listFinder, findsOneWidget);
    expect(
      tester.getSemantics(listFinder).identifier,
      Exp1Ids.list(groceries.id),
    );

    await tester.tap(listFinder);
    await settle(tester);
    expect(find.text('Coffee'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey(Exp1Ids.addTask)));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Tea');
    await tester.tap(find.byKey(const ValueKey(Exp1Ids.dialogOk)));
    await settle(tester);
    expect(find.text('Tea'), findsOneWidget);
    expect(
      (await tester.runAsync(() => db.getList(groceries.id)))!.taskCount,
      4,
    );

    await tester.runAsync(db.close);
  });
}
