import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_test/sqflite_test.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

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
  var context = await SqfliteServerTestContext.connect();
  if (context != null) {
    var factory = context.databaseFactory;

    test("Issue#144", () async {
      /*

      initDb() async {
        String databases_path = await getDatabasesPath();
        String path = join(databases_path, 'example.db');

        print(FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.notFound); // false
        Database oldDB = await openDatabase(path);
        List count = await oldDB.rawQuery(
            "select 'name' from sqlite_master where name = 'example_table'");
        print(count.length); // 0

        print('copy from asset');
        await deleteDatabase(path);
        print(FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.notFound); // true
        ByteData data =
            await rootBundle.load(join("assets", 'example.db')); // 6,9 MB

        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes);
        Database db = await openDatabase(path);
        print(FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.notFound); // false
        List count2 = await db.rawQuery(
            "select 'name' from sqlite_master where name = 'example_table'");
        print(count2.length); // 0 should 1

        return db; // should
      }

       */
      // Sqflite.devSetDebugModeOn(true);
      // Try to insert string with quote
      String path = await context.initDeleteDb("exp_issue_144.db");
      var rootBundle = TestAssetBundle();
      Database db;
      print('current dir: ${absolute(Directory.current.path)}');
      print('path: $path');
      try {
        Future<Database> initDb() async {
          Database oldDB = await factory.openDatabase(path);
          List count = await oldDB
              .rawQuery("select 'name' from sqlite_master where name = 'Test'");
          print(count.length); // 0

          // IMPORTANT! Close the database before deleting it
          await oldDB.close();

          print('copy from asset');
          await factory.deleteDatabase(path);
          ByteData data = await rootBundle.load(join("assets", 'example.db'));

          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          //print(bytes);
          expect(bytes.length, greaterThan(1000));
          // Writing the database
          await context.writeFile(path, bytes);
          Database db = await factory.openDatabase(path,
              options: OpenDatabaseOptions(readOnly: true));
          List count2 = await db
              .rawQuery("select 'name' from sqlite_master where name = 'Test'");
          print(count2);

          // Our database as a single table with a single element
          List<Map<String, dynamic>> list =
              await db.rawQuery("SELECT * FROM Test");
          print("list $list");
          // list [{id: 1, name: simple value}]
          expect(list.first["name"], "simple value");

          return db; // should
        }

        db = await initDb();
      } finally {
        await db?.close();
      }
    });

    test('Issue#146', () => issue146(context));
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
  int id;
  String name;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'name': name};
  }
}

class Classroom extends Item {
  Teacher _teacher;
  List<Student> _students;

  Teacher getTeacher() => _teacher;

  List<Student> getStudents() => _students;
}

class Teacher extends Item {}

class Student extends Item {}

TeacherProvider _teacherProvider;
StudentProvider _studentProvider;

Future issue146(SqfliteServerTestContext context) async {
  //context.devSetDebugModeOn(true);
  try {
    String path = await context.initDeleteDb("exp_issue_146.db");
    database = await context.databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (Database db, int version) {
              db.execute(
                  'CREATE TABLE Test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
            }));

    _teacherProvider = TeacherProvider();
    _studentProvider = StudentProvider();
    var _classroomProvider = ClassroomProvider();
    var room = Classroom()..name = 'room1';
    room._teacher = Teacher()..name = 'teacher1';
    room._students = [Student()..name = 'student1'];
    await _classroomProvider.insert(room);
  } finally {
    database?.close();
    database = null;
  }
}

Database database;

class ClassroomProvider {
  Future<Classroom> insert(Classroom room) async {
    return database.transaction((txn) async {
      await _teacherProvider.txnInsert(txn, room.getTeacher());
      await _studentProvider.txnBulkInsert(
          txn, room.getStudents()); // nest transaction here
      // Insert room last to save the teacher and students ids
      room.id = await txn.insert(tableClassroom, room.toMap());
      return room;
    });
  }
}

class TeacherProvider {
  Future<Teacher> insert(Teacher teacher) =>
      database.transaction((txn) => txnInsert(txn, teacher));

  Future<Teacher> txnInsert(Transaction txn, Teacher teacher) async {
    teacher.id = await txn.insert(tableTeacher, teacher.toMap());
    return teacher;
  }
}

class StudentProvider {
  Future<List<Student>> bulkInsert(List<Student> students) =>
      database.transaction((txn) => txnBulkInsert(txn, students));

  Future<List<Student>> txnBulkInsert(
      Transaction txn, List<Student> students) async {
    for (var student in students) {
      student.id = await txn.insert(tableStudent, student.toMap());
    }
    return students;
  }
}
