import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:sqflite_porter/utils/csv_utils.dart';

void expectCsv(String value, String expected) {
  expect(const LineSplitter().convert(value),
      const LineSplitter().convert(expected));
}

void main() {
  group("src_csv_utils", () {
    test('mapListToCsv', () {
      // null
      expect(mapListToCsv(null), isNull);
      // empty
      expect(mapListToCsv(<Map<String, dynamic>>[]), '');

      // simple
      expectCsv(
          mapListToCsv([
            {'test': 1}
          ]),
          '''
test
1
''');

      // different keys
      expectCsv(
          mapListToCsv([
            {'test': 1},
            {'value': 2}
          ]),
          '''
test,value
1,null
null,2
''');
      // all types
      expectCsv(
          mapListToCsv([
            {
              'int': 1,
              'double': 2.0,
              'String': 'text',
              'bool': true,
              'Uint8List': Uint8List.fromList([1, 2, 3])
            }
          ]),
          '''
int,double,String,bool,Uint8List
1,2.0,text,true,"[1, 2, 3]"
''');
    });
  });
}
