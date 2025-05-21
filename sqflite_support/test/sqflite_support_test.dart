import 'package:sqflite_support/sqflite_support.dart';
import 'package:test/test.dart';

void main() {
  group('sqflite_support', () {
    test('add sqflite', () {
      expect(
        pubspecStringAddSqflite('dependencies:'),
        'dependencies:\n  sqflite:',
      );
      expect(
        pubspecStringAddSqflite('''

dependencies:
 dependencies:
'''),
        '''

dependencies:
  sqflite:
 dependencies:
''',
      );
    });
  });
}
