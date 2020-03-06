import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_porter/src/sqlite_porter.dart';

void main() {
  group('src/sqflite_porter', () {
    test('extract_table_name', () {
      expect(
          extractTableName("CREATE TABLE IF NOT EXISTS 'artists' (value TEXT)"),
          "'artists'");
      expect(extractTableName("CREATE TABLE 'albums'"), "'albums'");
    });
  });
}
