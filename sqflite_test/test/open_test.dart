import 'dart:async';
import 'dart:io';
import 'package:pedantic/pedantic.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:synchronized/synchronized.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:sqflite_test/sqflite_test.dart';
import 'package:sqflite/utils/utils.dart' as utils;

bool verify(bool condition, [String message]) {
  message ??= "verify failed";
  expect(condition, true, reason: message);
  return condition;
}

class OpenCallbacks {
  OpenCallbacks(this.databaseFactory) {
    onConfigure = (Database db) {
      //print("onConfigure");
      //verify(!onConfigureCalled, "onConfigure must be called once");
      expect(onConfigureCalled, false,
          reason:
              "onConfigure already called"); // onConfigure must be called once
      onConfigureCalled = true;
    };

    onCreate = (Database db, int version) {
      //print("onCreate");
      expect(onConfigureCalled, true, reason: "onConfigure not called");
      expect(onCreateCalled, false, reason: "onCreate already called");
      onCreateCalled = true;
    };

    onOpen = (Database db) {
      //print("onOpen");
      expect(onConfigureCalled, isTrue,
          reason: "onConfigure must be called before onOpen");
      expect(onOpenCalled, isFalse, reason: "onOpen already called");
      onOpenCalled = true;
    };

    onUpgrade = (Database db, int oldVersion, int newVersion) {
      verify(onConfigureCalled, "onConfigure not called in onUpgrade");
      verify(!onUpgradeCalled, "onUpgradeCalled already called");
      onUpgradeCalled = true;
    };

    onDowngrade = (Database db, int oldVersion, int newVersion) {
      verify(onConfigureCalled, "onConfigure not called");
      verify(!onDowngradeCalled, "onDowngrade already called");
      onDowngradeCalled = true;
    };

    reset();
  }

  final DatabaseFactory databaseFactory;
  bool onConfigureCalled;
  bool onOpenCalled;
  bool onCreateCalled;
  bool onDowngradeCalled;
  bool onUpgradeCalled;

  OnDatabaseCreateFn onCreate;
  OnDatabaseConfigureFn onConfigure;
  OnDatabaseVersionChangeFn onDowngrade;
  OnDatabaseVersionChangeFn onUpgrade;
  OnDatabaseOpenFn onOpen;

  void reset() {
    onConfigureCalled = false;
    onOpenCalled = false;
    onCreateCalled = false;
    onDowngradeCalled = false;
    onUpgradeCalled = false;
  }

  Future<Database> open(String path, {int version}) async {
    reset();
    return await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: version,
            onCreate: onCreate,
            onConfigure: onConfigure,
            onDowngrade: onDowngrade,
            onUpgrade: onUpgrade,
            onOpen: onOpen));
  }
}

Future main() {
  return testMain(run);
}

void run(SqfliteServerTestContext context) {
  var factory = context.databaseFactory;
  test('Databases path', () async {
    // await utils.devSetDebugModeOn(false);
    var databasesPath = await factory.getDatabasesPath();
    // On Android we know it is current a "databases" folder in the package folder
    print("databasesPath: " + databasesPath);
    if (Platform.isAndroid) {
      expect(basename(databasesPath), "databases");
    } else if (Platform.isIOS) {
      expect(basename(databasesPath), "Documents");
    }
    String path =
        context.pathContext.join(databasesPath, "in_default_directory.db");
    await factory.deleteDatabase(path);
    Database db = await factory.openDatabase(path);
    await db.close();
  });

  Future<bool> checkFileExists(String path) async {
    bool exists = false;
    try {
      Database db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
      exists = true;
      await db.close();
    } catch (_) {}
    return exists;
  }

  test("Delete database", () async {
    // await context.devSetDebugModeOn(false);
    String path = await context.initDeleteDb("delete_database.db");
    expect(await checkFileExists(path), isFalse);
    Database db = await factory.openDatabase(path);
    await db.close();

    expect(await checkFileExists(path), isTrue);

    // expect((await new File(path).exists()), true);
    print("Deleting database $path");
    await factory.deleteDatabase(path);
    // expect((await new File(path).exists()), false);
    expect(await checkFileExists(path), isFalse);
  });

  test("Open no version", () async {
    //await utils.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("open_no_version.db");
    expect(await checkFileExists(path), false);
    Database db = await factory.openDatabase(path);
    verify(await checkFileExists(path));
    await db.close();
  });

  test('open in sub directory', () async {
    // await context.devSetDebugModeOn(true);
    String path =
        await context.deleteDirectory(join('sub_that_should_not_exists'));
    var dbPath = join(path, 'open.db');
    var db = await factory.openDatabase(dbPath);
    try {} finally {
      await db.close();
    }
  });

  test('open in sub sub directory', () async {
    // await context.devSetDebugModeOn(true);
    String path = await context
        .deleteDirectory(join('sub2_that_should_not_exists', 'sub_sub'));
    var dbPath = join(path, 'open.db');
    var db = await factory.openDatabase(dbPath);
    try {} finally {
      await db.close();
    }
  });

  test("isOpen", () async {
    //await utils.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("is_open.db");
    expect(await checkFileExists(path), false);
    Database db = await factory.openDatabase(path);
    expect(db.isOpen, true);
    verify(await checkFileExists(path));
    await db.close();
    expect(db.isOpen, false);
  });

  test("Open no version onCreate", () async {
    // should fail
    String path = await context.initDeleteDb("open_no_version_on_create.db");
    verify(!(File(path).existsSync()));
    Database db;
    try {
      db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(onCreate: (Database db, int version) {
        // never called
        verify(false);
      }));
      verify(false);
    } on ArgumentError catch (_) {}
    verify(!File(path).existsSync());
    expect(db, null);
  });

  test("Open onCreate", () async {
    // await utils.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("open_test2.db");
    bool onCreate = false;
    bool onCreateTransaction = false;
    Database db = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (Database db, int version) async {
              expect(version, 1);
              onCreate = true;

              await db.transaction((txn) async {
                await txn
                    .execute("CREATE TABLE Test2 (id INTEGER PRIMARY KEY)");
                onCreateTransaction = true;
              });
            }));
    verify(onCreate);
    expect(onCreateTransaction, true);
    await db.close();
  });

  test("Open 2 databases", () async {
    //await utils.devSetDebugModeOn(true);
    String path1 = await context.initDeleteDb("open_db_1.db");
    String path2 = await context.initDeleteDb("open_db_2.db");
    Database db1 = await factory.openDatabase(path1,
        options: OpenDatabaseOptions(version: 1));
    Database db2 = await factory.openDatabase(path2,
        options: OpenDatabaseOptions(version: 1));
    await db1.close();
    await db2.close();
  });

  test("Open onUpgrade", () async {
    bool onUpgrade = false;
    String path = await context.initDeleteDb("open_on_upgrade.db");
    Database database = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (Database db, int version) async {
              await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
            }));
    try {
      await database.insert("Test", <String, dynamic>{'id': 1, 'name': 'test'});
      fail('should fail');
    } on DatabaseException catch (e) {
      print(e);
    }
    await database.close();
    database = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 2,
            onUpgrade: (Database db, int oldVersion, int newVersion) async {
              expect(oldVersion, 1);
              expect(newVersion, 2);
              await db.execute("ALTER TABLE Test ADD name TEXT");
              onUpgrade = true;
            }));
    verify(onUpgrade);

    expect(
        await database
            .insert("Test", <String, dynamic>{'id': 1, 'name': 'test'}),
        1);
    await database.close();
  });

  test("Open onDowngrade", () async {
    String path = await context.initDeleteDb("open_on_downgrade.db");
    Database database = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 2,
            onCreate: (Database db, int version) async {
              await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
            },
            onDowngrade: (Database db, int oldVersion, int newVersion) async {
              verify(false, "should not be called");
            }));
    await database.close();

    bool onDowngrade = false;
    database = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onDowngrade: (Database db, int oldVersion, int newVersion) async {
              expect(oldVersion, 2);
              expect(newVersion, 1);
              await db.execute("ALTER TABLE Test ADD name TEXT");
              onDowngrade = true;
            }));
    verify(onDowngrade);

    await database.close();
  });

  test("Open bad path", () async {
    try {
      await factory.openDatabase("/invalid_path");
      fail('should fail');
    } on DatabaseException catch (e) {
      expect(e.toString(), contains('open_failed'));
      // expect(e.isOpenFailedError(), isTrue, reason: e.toString());
    }
  });

  test("Open on configure", () async {
    String path = await context.initDeleteDb("open_on_configure.db");

    bool onConfigured = false;
    bool onConfiguredTransaction = false;
    Future _onConfigure(Database db) async {
      onConfigured = true;
      await db.execute("CREATE TABLE Test1 (id INTEGER PRIMARY KEY)");
      await db.transaction((txn) async {
        await txn.execute("CREATE TABLE Test2 (id INTEGER PRIMARY KEY)");
        onConfiguredTransaction = true;
      });
    }

    var db = await factory.openDatabase(path,
        options: OpenDatabaseOptions(onConfigure: _onConfigure));
    expect(onConfigured, true);
    expect(onConfiguredTransaction, true);

    await db.close();
  });

  test("Open onDowngrade delete", () async {
    // await utils.devSetDebugModeOn(false);

    String path = await context.initDeleteDb("open_on_downgrade_delete.db");
    Database database = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 3,
            onCreate: (Database db, int version) async {
              await db.execute("CREATE TABLE Test(id INTEGER PRIMARY KEY)");
            }));
    await database.close();

    // should fail going back in versions
    bool onCreated = false;
    bool onOpened = false;
    bool onConfiguredOnce = false; // onConfigure will be called twice here
    // since the database is re-opened
    bool onConfigured = false;
    database = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 2,
            onConfigure: (Database db) {
              // Must not be configured nor created yet
              verify(!onConfigured);
              verify(!onCreated);
              if (!onConfiguredOnce) {
                // first time
                onConfiguredOnce = true;
              } else {
                onConfigured = true;
              }
            },
            onCreate: (Database db, int version) {
              verify(onConfigured);
              verify(!onCreated);
              verify(!onOpened);
              onCreated = true;
              expect(version, 2);
            },
            onOpen: (Database db) {
              verify(onCreated);
              onOpened = true;
            },
            onDowngrade: onDatabaseDowngradeDelete));
    await database.close();

    expect(onCreated, true);
    expect(onOpened, true);
    expect(onConfigured, true);

    onCreated = false;
    onOpened = false;

    database = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 2,
            onCreate: (Database db, int version) {
              expect(false, "should not be called");
            },
            onOpen: (Database db) {
              onOpened = true;
            },
            onDowngrade: onDatabaseDowngradeDelete));
    expect(onOpened, true);
    await database.close();
  });

  test("All open callback", () async {
    // await utils.devSetDebugModeOn(false);
    String path = await context.initDeleteDb("open_all_callbacks.db");

    int step = 1;
    OpenCallbacks openCallbacks = OpenCallbacks(factory);
    var db = await openCallbacks.open(path, version: 1);
    verify(openCallbacks.onConfigureCalled, "onConfiguredCalled $step");
    verify(openCallbacks.onCreateCalled, "onCreateCalled $step");
    verify(openCallbacks.onOpenCalled, "onOpenCalled $step");
    verify(!openCallbacks.onUpgradeCalled, "onUpdateCalled $step");
    verify(!openCallbacks.onDowngradeCalled, "onDowngradCalled $step");
    await db.close();

    ++step;
    db = await openCallbacks.open(path, version: 3);
    verify(openCallbacks.onConfigureCalled, "onConfiguredCalled $step");
    verify(!openCallbacks.onCreateCalled, "onCreateCalled $step");
    verify(openCallbacks.onOpenCalled, "onOpenCalled $step");
    verify(openCallbacks.onUpgradeCalled, "onUpdateCalled $step");
    verify(!openCallbacks.onDowngradeCalled, "onDowngradCalled $step");
    await db.close();

    ++step;
    db = await openCallbacks.open(path, version: 2);
    verify(openCallbacks.onConfigureCalled, "onConfiguredCalled $step");
    verify(!openCallbacks.onCreateCalled, "onCreateCalled $step");
    verify(openCallbacks.onOpenCalled, "onOpenCalled $step");
    verify(!openCallbacks.onUpgradeCalled, "onUpdateCalled $step");
    verify(openCallbacks.onDowngradeCalled, "onDowngradCalled $step");
    await db.close();

    openCallbacks.onDowngrade = onDatabaseDowngradeDelete;
    int configureCount = 0;
    var callback = openCallbacks.onConfigure;
    // allow being called twice
    openCallbacks.onConfigure = (Database db) {
      if (configureCount == 1) {
        openCallbacks.onConfigureCalled = false;
      }
      configureCount++;
      callback(db);
    };
    ++step;
    db = await openCallbacks.open(path, version: 1);

    /*
      verify(openCallbacks.onConfigureCalled,"onConfiguredCalled $step");
      verify(configureCount == 2, "onConfigure count");
      verify(openCallbacks.onCreateCalled, "onCreateCalled $step");
      verify(openCallbacks.onOpenCalled, "onOpenCalled $step");
      verify(!openCallbacks.onUpgradeCalled, "onUpdateCalled $step");
      verify(!openCallbacks.onDowngradeCalled, "onDowngradCalled $step");
      */
    await db.close();
  });

  test("Open batch", () async {
    // await utils.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("open_batch.db");

    Future _onConfigure(Database db) async {
      var batch = db.batch();
      batch.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
      await batch.commit();
    }

    Future _onCreate(Database db, int version) async {
      var batch = db.batch();
      batch.rawInsert('INSERT INTO Test(value) VALUES("value1")');
      await batch.commit();
    }

    Future _onOpen(Database db) async {
      var batch = db.batch();
      batch.rawInsert('INSERT INTO Test(value) VALUES("value2")');
      await batch.commit();
    }

    var db = await factory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onConfigure: _onConfigure,
            onCreate: _onCreate,
            onOpen: _onOpen));
    expect(
        utils.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test")), 2);

    await db.close();
  });

  test("Open read-only", () async {
    // await context.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("open_read_only.db");

    Future _onCreate(Database db, int version) async {
      var batch = db.batch();
      batch.execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
      batch.rawInsert('INSERT INTO Test(value) VALUES("value1")');
      await batch.commit();
    }

    var db = await factory.openDatabase(path,
        options: OpenDatabaseOptions(version: 1, onCreate: _onCreate));
    expect(
        utils.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test")), 1);

    await db.close();

    db = await factory.openDatabase(path,
        options: OpenDatabaseOptions(readOnly: true));
    expect(
        utils.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM Test")), 1);

    try {
      await db.rawInsert('INSERT INTO Test(value) VALUES("value1")');
      fail("should fail");
    } on DatabaseException catch (e) {
      // Error DatabaseException(attempt to write a readonly database (code 8)) running Open read-only
      expect(e.isReadOnlyError(), true);
    }

    var batch = db.batch();
    batch.rawQuery("SELECT COUNT(*) FROM Test");
    await batch.commit();

    await db.close();
  });

  test('Open demo (doc)', () async {
    // await utils.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("open_read_only.db");

    {
      Future _onConfigure(Database db) async {
        // Add support for cascade delete
        await db.execute("PRAGMA foreign_keys = ON");
      }

      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(onConfigure: _onConfigure));
      await db.close();
    }

    {
      Future _onCreate(Database db, int version) async {
        // Database is created, delete the table
        await db
            .execute("CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)");
      }

      Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
        // Database version is updated, alter the table
        await db.execute("ALTER TABLE Test ADD name TEXT");
      }

      // Special callback used for onDowngrade here to recreate the database
      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
              version: 1,
              onCreate: _onCreate,
              onUpgrade: _onUpgrade,
              onDowngrade: onDatabaseDowngradeDelete));
      await db.close();
    }

    {
      Future _onOpen(Database db) async {
        // Database is open, print its version
        print('db version ${await db.getVersion()}');
      }

      var db = await factory.openDatabase(path,
          options: OpenDatabaseOptions(
            onOpen: _onOpen,
          ));
      await db.close();
    }

    // asset (use existing copy if any)
    {
      // Check if we have an existing copy first
      var databasesPath = await factory.getDatabasesPath();
      String path = join(databasesPath, "demo_asset_example.db");

      // try opening (will work if it exists)
      Database db;
      try {
        db = await factory.openDatabase(path,
            options: OpenDatabaseOptions(readOnly: true));
      } catch (e) {
        print("Error $e");
      }

      await db?.close();
    }
  });

  test('Database locked (doc)', () async {
    // await utils.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("open_locked.db");
    var helper = Helper(factory, path);

    // without the synchronized fix, this could faild
    for (int i = 0; i < 100; i++) {
      unawaited(helper.getDb());
    }
    var db = await helper.getDb();
    await db.close();
  });

  test('single/multi instance (using factory)', () async {
    // await utils.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("instances_test.db");
    var db1 = await factory.openDatabase(path,
        options: OpenDatabaseOptions(singleInstance: false));
    var db2 = await factory.openDatabase(path,
        options: OpenDatabaseOptions(singleInstance: true));
    var db3 = await factory.openDatabase(path,
        options: OpenDatabaseOptions(singleInstance: true));
    verify(db1 != db2);
    verify(db2 == db3);
    await db1.close();
    await db2.close();
    await db3.close(); // safe to close the same instance
  });

  test('single/multi instance', () async {
    // await utils.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("instances_test.db");
    var db1 = await factory.openDatabase(path,
        options: OpenDatabaseOptions(singleInstance: false));
    var db2 = await factory.openDatabase(path,
        options: OpenDatabaseOptions(singleInstance: true));
    var db3 = await factory.openDatabase(path,
        options: OpenDatabaseOptions(singleInstance: true));
    verify(db1 != db2);
    verify(db2 == db3);
    await db1.close();
    await db2.close();
    await db3.close(); // safe to close the same instance
  });

  test('In memory database', () async {
    // await context.devSetDebugModeOn(true);
    String inMemoryPath =
        inMemoryDatabasePath; // tried null without success, as it crashes on Android
    String path = inMemoryPath;

    var db = await factory.openDatabase(path);
    try {
      await db
          .execute("CREATE TABLE IF NOT EXISTS Test(id INTEGER PRIMARY KEY)");
      await db.insert("Test", <String, dynamic>{"id": 1});
      expect(await db.query("Test"), [
        {"id": 1}
      ]);

      await db.close();

      // reopen, content should be gone
      db = await factory.openDatabase(path);
      try {
        await db.query("Test");
        fail("fail");
      } on DatabaseException catch (e) {
        print(e);
      }
    } finally {
      await db.close();
    }
  });

  test('Not in memory database', () async {
    // await utils.devSetDebugModeOn(true);
    String path = await context.initDeleteDb("not_in_memory.db");

    var db = await factory.openDatabase(path);
    await db.execute("CREATE TABLE IF NOT EXISTS Test(id INTEGER PRIMARY KEY)");
    await db.insert("Test", <String, dynamic>{"id": 1});
    expect(await db.query("Test"), [
      {"id": 1}
    ]);
    await db.close();

    // reopen, content should be done
    db = await factory.openDatabase(path);
    expect(await db.query("Test"), [
      {"id": 1}
    ]);
    await db.close();
  });
}

class Helper {
  Helper(this.databaseFactory, this.path);

  final DatabaseFactory databaseFactory;
  final String path;
  Database _db;
  final _lock = Lock();

  Future<Database> getDb() async {
    if (_db == null) {
      await _lock.synchronized(() async {
        // Check again once entering the synchronized block
        if (_db == null) {
          _db = await databaseFactory.openDatabase(path);
        }
      });
    }
    return _db;
  }
}
