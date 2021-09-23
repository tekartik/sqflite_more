import 'package:sqflite_common_porter/src/sqlite_porter.dart';
import 'package:test/test.dart';

void main() {
  group('src/sqflite_common_porter', () {
    test('extract_table_name', () {
      expect(
          extractTableName("CREATE TABLE IF NOT EXISTS 'artists' (value TEXT)"),
          "'artists'");
      expect(extractTableName("CREATE TABLE 'albums'"), "'albums'");
    });
  });
}
