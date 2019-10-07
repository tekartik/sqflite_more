import 'package:test_api/test_api.dart';
import 'package:sqflite_test/database_factory_mock.dart';

void main() {
  group('database_factory_mock', () {
    test('databaseFactoryMock', () async {
      final factory = DatabaseFactoryMock();
      expect(await factory.openDatabase(null), isNull);
      expect(await factory.databaseExists(null), false);
      await factory.deleteDatabase(null);
      expect(await factory.getDatabasesPath(), isNull);
    });
  });
}
