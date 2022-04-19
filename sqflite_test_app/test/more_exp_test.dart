import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_test/sqflite_test.dart';
import 'package:test/test.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    //if (key == 'resources/test')
    return ByteData.view(
        Uint8List.fromList(await File(key).readAsBytes()).buffer);
    // return null;
  }
}

Future main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  var context = await SqfliteServerTestContext.connect();
  if (context != null) {
    var factory = context.databaseFactory;

    test('Issue#144', () async {
      /*

      initDb() async {
        String databases_path = await getDatabasesPath();
        var path =join(databases_path, 'example.db');

        print(FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.notFound); // false
        Database oldDB = await openDatabase(path);
        List count = await oldDB.rawQuery(
            'select 'name' from sqlite_master where name = 'example_table'');
        print(count.length); // 0

        print('copy from asset');
        await deleteDatabase(path);
        print(FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.notFound); // true
        ByteData data =
            await rootBundle.load(join('assets', 'example.db')); // 6,9 MB

        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes);
        var db =await openDatabase(path);
        print(FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.notFound); // false
        List count2 = await db.rawQuery(
            'select 'name' from sqlite_master where name = 'example_table'');
        print(count2.length); // 0 should 1

        return db; // should
      }

       */
      // Sqflite.devSetDebugModeOn(true);
      // Try to insert string with quote
      var path = await context.initDeleteDb('exp_issue_144.db');
      var rootBundle = TestAssetBundle();
      Database? db;
      print('current dir: ${absolute(Directory.current.path)}');
      print('path: $path');
      try {
        Future<Database> initDb() async {
          var oldDB = await factory.openDatabase(path);
          List count = await oldDB
              .rawQuery("select 'name' from sqlite_master where name = 'Test'");
          print(count.length); // 0

          // IMPORTANT! Close the database before deleting it
          await oldDB.close();

          print('copy from asset');
          await factory.deleteDatabase(path);
          var data = await rootBundle.load(join('assets', 'example.db'));

          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          //print(bytes);
          expect(bytes.length, greaterThan(1000));
          // Writing the database
          await context.writeFile(path, bytes);
          var db = await factory.openDatabase(path,
              options: OpenDatabaseOptions(readOnly: true));
          List count2 = await db
              .rawQuery("select 'name' from sqlite_master where name = 'Test'");
          print(count2);

          // Our database as a single table with a single element
          var list = await db.rawQuery('SELECT * FROM Test');
          print('list $list');
          // list [{id: 1, name: simple value}]
          expect(list.first['name'], 'simple value');

          return db; // should
        }

        db = await initDb();
      } finally {
        await db?.close();
      }
    }, skip: true);

    test('Issue#146', () => issue146(context));

    test('Issue#159', () async {
      var db = DbHelper(context);
      var user1 = User('User1');
      var insertResult = await db.saveUser(user1);
      print('insert result is $insertResult');
      var searchResult = await db.retrieveUser(insertResult);
      print(searchResult.toString());
    });
    test('primary key', () async {
      var path = await context.initDeleteDb('primary_key.db');
      var db = await factory.openDatabase(path);
      try {
        var table = 'test';
        await db
            .execute('CREATE TABLE $table (id INTEGER PRIMARY KEY, name TEXT)');
        var id = await db.insert(table, <String, Object?>{'name': 'test'});
        var id2 = await db.insert(table, <String, Object?>{'name': 'test'});

        print('inserted $id, $id2');
        // inserted in a wrong order to check ASC/DESC

        print(await db.query(table));
        //await db
      } finally {
        await db.close();
      }
    });

    test('Issue#246', () async {
      var path = await context.initDeleteDb('primary_key.db');
      var db = await factory.openDatabase(path);
      try {
        var table = 'test';
        await db
            .execute('CREATE TABLE $table (id INTEGER PRIMARY KEY, name TEXT)');
        var id = await db.insert(table, <String, Object?>{'name': 'test'});
        var id2 = await db.insert(table, <String, Object?>{'name': 'test'});

        print('inserted $id, $id2');
        // inserted in a wrong order to check ASC/DESC

        print(await db.query(table));
        //await db
      } finally {
        await db.close();
      }
    });

    test('Issue#242', () async {
      var path = await context.initDeleteDb('issue_242.db');
      var db = await factory.openDatabase(path);
      try {
        await db.execute('''
      CREATE TABLE test (
    f1 TEXT PRIMARY KEY NOT NULL,
    f2 INTEGER NOT NULL); 
      ''');
        await db.execute('CREATE INDEX test_index ON test(f2);');
        //await db
      } finally {
        await db.close();
      }
    });

    test('Issue#246', () async {
      var path = await context.initDeleteDb('Issue_246.db');
      var db = await factory.openDatabase(path);
      try {
        print(await db.query('sqlite_master', columns: ['name']));
        //await db
      } finally {
        await db.close();
      }
    });

    test('Issue#268', () async {
      var path = await context.initDeleteDb('Issue_268.db');
      var db = await factory.openDatabase(path);
      try {
        // print('like %meta%');
        var result = await db.rawQuery(
            'SELECT * FROM sqlite_master WHERE name LIKE ?', ['%meta%']);
        // print(result);
        expect(result.length, 1);
        //await db
      } finally {
        await db.close();
      }
    });

    test('Issue#270', () async {
      var path = await context.initDeleteDb('Issue_270.db');
      var db = await factory.openDatabase(path);
      try {
        var batch = db.batch();
        batch.execute('''CREATE TABLE konular (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT
)''');

        batch.execute('ALTER TABLE konular ADD COLUMN ks INTEGER');
        await batch.commit();
        var result = await db.rawQuery(
            'SELECT * FROM sqlite_master WHERE name LIKE ?', ['konu%']);
        print(result);
        expect(result.length, 1);
        //await db
      } finally {
        await db.close();
      }
    });

    test('Issue#285', () async {
      // Type real as int
      var path = await context.initDeleteDb('issue_285.db');
      var db = await factory.openDatabase(path);
      try {
        var batch = db.batch();
        batch.execute('''
  CREATE TABLE test (
    id INTEGER PRIMARY KEY,
    value REAL NOT NULL
  ); 
''');
// Insert an int
        batch.insert('test', {'id': 3, 'value': 2});
// Insert 2 floats
        batch.insert('test', {'id': 1, 'value': 1.5});
        batch.insert('test', {'id': 2, 'value': 2.5});
        batch.query('test', orderBy: 'value ASC');
        var result = (await batch.commit())[4] as List<Map>;
        expect(result[0]['id'], 1);
        expect(result[1]['id'], 3);
        expect(result[2]['id'], 2);
        expect(result[0]['value'], 1.5);
// It was inserted as an int, but it is still a double
        expect(result[1]['value'], 2);
        expect(result[1]['value'], const TypeMatcher<double>());
        expect(result[2]['value'], 2.5);
      } finally {
        await db.close();
      }
    });

    test('Issue#297', () async {
      Future<Database> openDatabase(String path) async {
        path = await context.initDeleteDb(path);
        var db = await factory.openDatabase(path);
        return db;
      }

      // Custom version handling
      var db = await openDatabase('notes.db');

      // We want version 2
      var oldVersion = await db.getVersion();
      var newVersion = 2;

      if (oldVersion == 0) {
        // Create...
      } else if (oldVersion == 1) {
        // Update...
      }
      if (oldVersion < newVersion) {
        // We are at version 2 now
        await db.setVersion(newVersion);
      }

      await db.close();
    });

    test('Version', () async {
      // Custom version handling
      var db = await factory.openDatabase(inMemoryDatabasePath);

      // Print the version
      print(await db.rawQuery('SELECT sqlite_version()'));

      await db.close();
    });

    test('Issue#310', () async {
      var db = await factory.openDatabase(inMemoryDatabasePath);
      await db.rawQuery(
          'CREATE VIRTUAL TABLE mytable2 USING fts4(description text)');
      await db.rawQuery(
          'CREATE VIRTUAL TABLE mytable2_terms USING fts4aux(mytable2)');
      await db
          .rawQuery('CREATE VIRTUAL TABLE mytable3 USING spellfix(word text)');
      await db.rawQuery(
          "INSERT INTO mytable2 VALUES ('All the Carmichael numbers')");
      await db.rawQuery("INSERT INTO mytable2 VALUES ('They are great')");
      await db
          .rawQuery("INSERT INTO mytable2 VALUES ('Here some other numbers')");

      await db.rawQuery('CREATE VIRTUAL TABLE demo USING spellfix1;');
//here error occured
      await db.rawQuery(
          "INSERT INTO demo(word) SELECT term FROM mytable2_terms WHERE col='*';");
      await db.close();
    }, skip: true);
  }
}

/// Issue 146

/* original
class ClassroomProvider {
  Future<Classroom> insert(Classroom room) async {
    return database.transaction((txn) async {
      room.id = await db.insert(tableClassroom, room.toMap());
      await _teacherProvider.insert(room.getTeacher());
      await _studentProvider.bulkInsert(
          room.getStudents()); // nest transaction here
      return room;
    }
        }

  );
}}

class TeacherProvider {
  Future<Teacher> insert(Teacher teacher) async {
    teacher.id = await db.insert(tableTeacher, teacher.toMap());
    return teacher;
  }
}

class StudentProvider {
  Future<List<Student>> bulkInsert(List<Student> students) async {
    // use database object in a transaction here !!!
    return database.transaction((txn) async {
      for (var s in students) {
        s.id = await db.insert(tableStudent, student.toMap());
      }
      return students;
    });
  }
}
*/

String tableItem = 'Test';
String tableClassroom = tableItem;
String tableTeacher = tableItem;
String tableStudent = tableItem;

class Item {
  int? id;
  String? name;

  Map<String, Object?> toMap() {
    return <String, Object?>{'name': name};
  }
}

class Classroom extends Item {
  Teacher? _teacher;
  List<Student>? _students;

  Teacher? getTeacher() => _teacher;

  List<Student>? getStudents() => _students;
}

class Teacher extends Item {}

class Student extends Item {}

late TeacherProvider _teacherProvider;
late StudentProvider _studentProvider;

Future issue146(SqfliteServerTestContext context) async {
  //context.devSetDebugModeOn(true);
  try {
    var path = await context.initDeleteDb('exp_issue_146.db');
    database = await context.databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (Database db, int version) {
              db.execute(
                  'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
            }));

    _teacherProvider = TeacherProvider();
    _studentProvider = StudentProvider();
    var classroomProvider = ClassroomProvider();
    var room = Classroom()..name = 'room1';
    room._teacher = Teacher()..name = 'teacher1';
    room._students = [Student()..name = 'student1'];
    await classroomProvider.insert(room);
  } finally {
    await database?.close();
    database = null;
  }
}

Database? database;

class ClassroomProvider {
  Future<Classroom> insert(Classroom room) async {
    return database!.transaction((txn) async {
      await _teacherProvider.txnInsert(txn, room.getTeacher()!);
      await _studentProvider.txnBulkInsert(
          txn, room.getStudents()!); // nest transaction here
      // Insert room last to save the teacher and students ids
      room.id = await txn.insert(tableClassroom, room.toMap());
      return room;
    });
  }
}

class TeacherProvider {
  Future<Teacher> insert(Teacher teacher) =>
      database!.transaction((txn) => txnInsert(txn, teacher));

  Future<Teacher> txnInsert(Transaction txn, Teacher teacher) async {
    teacher.id = await txn.insert(tableTeacher, teacher.toMap());
    return teacher;
  }
}

class StudentProvider {
  Future<List<Student>> bulkInsert(List<Student> students) =>
      database!.transaction((txn) => txnBulkInsert(txn, students));

  Future<List<Student>> txnBulkInsert(
      Transaction txn, List<Student> students) async {
    for (var student in students) {
      student.id = await txn.insert(tableStudent, student.toMap());
    }
    return students;
  }
}

// Issue 159

class DbHelper {
  final SqfliteServerTestContext context;
  static Database? _db;

  DbHelper(this.context);

  void _onCreate(Database db, int newVersion) async {
    await db.execute(
        'CREATE TABLE MYTABLE(ID INTEGER PRIMARY KEY, userName TEXT NOT NULL)');
  }

  Future<Database> initDB() async {
    //Directory documentDirectory = await contextgetApplicationDocumentsDirectory();
    // var path =join(documentDirectory.path, 'appdb.db');
    var path = await context.initDeleteDb('issue159.db');
    var newDB = await context.databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(version: 1, onCreate: _onCreate));
    return newDB;
  }

  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    } else {
      _db = await initDB();
      return _db;
    }
  }

  Future<int> saveUser(User user) async {
    var dbClient = await (db as FutureOr<Database>);
    int result;
    var userMap = user.toMap();
    result = await dbClient.insert('MYTABLE', userMap);
    return result;
  }

  Future<User?> retrieveUser(int id) async {
    var dbClient = await db;
    var sql = 'SELECT * FROM MYTABLE WHERE ID = $id';
    var result = await dbClient!.rawQuery(sql);
    print(result);
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    } else {
      return null;
    }
  }
}

class User {
  String? _userName;
  int? _id;

  String? get userName => _userName;

  int? get id => _id;

  User(this._userName, [this._id]);

  User.map(Object? obj) {
    _userName = (obj as Map)['userName'] as String?;
    _id = obj['id'] as int?;
  }

  User.fromMap(Map<String, Object?> map) {
    _userName = map['userName'] as String?;
    if (map['id'] != null) {
      _id = map['id'] as int?;
    } else {
      print('in fromMap, Id is null');
    }
  }

  Map<String, Object?> toMap() {
    var map = <String, Object?>{};
    map['userName'] = _userName;
    if (_id != null) {
      map['id'] = _id;
    } else {
      print('in toMap, id is null');
    }
    return map;
  }

  @override
  String toString() {
    return 'ID is $_id , Username is $_userName }';
  }
}
