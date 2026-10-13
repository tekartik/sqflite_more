import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_porter/sqflite_porter.dart' as common;
import 'package:sqflite_porter/sqflite_porter.dart';

void main() {
  group('sqflite_porter', () {
    test('api', () {
      // The implementation is the one of sqflite_common_porter
      expect(dbExportSql, common.dbExportSql);
      expect(dbImportSql, common.dbImportSql);
    });
  });
}
