import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_porter/src/sql_parser.dart';

void main() {
  group("sql_parser", () {
    test("isWhitespace", () {
      var whitespaces = '\t\n\r ';
      for (int codeUnit in whitespaces.codeUnits) {
        expect(isWhitespace(codeUnit), isTrue, reason: 'codeUnit: $codeUnit');
      }
      var noWhitespaces = 'ab10';
      for (int codeUnit in noWhitespaces.codeUnits) {
        expect(isWhitespace(codeUnit), isFalse);
      }
    });

    test("isStringWrapper", () {
      var stringWrapper = '\'"`';
      for (int codeUnit in stringWrapper.codeUnits) {
        expect(isStringWrapper(codeUnit), isTrue,
            reason: 'codeUnit: $codeUnit');
      }
      var noStringWrapper = 'ab10 ';
      for (int codeUnit in noStringWrapper.codeUnits) {
        expect(isStringWrapper(codeUnit), isFalse);
      }
    });

    test("isSeparator", () {
      var separator = '(,#);';
      for (int codeUnit in separator.codeUnits) {
        expect(isSeparator(codeUnit), isTrue,
            reason: 'codeUnit: $codeUnit ${String.fromCharCode(codeUnit)}');
      }
      var noSeparator = 'ab10 \'"`';
      for (int codeUnit in noSeparator.codeUnits) {
        expect(isSeparator(codeUnit), isFalse);
      }
    });

    test("unescapeText", () {
      expect(unescapeText('table'), 'table');
      expect(unescapeText('"table"'), 'table');
      expect(unescapeText('"table'), 'table');
      expect(unescapeText('"table`'), 'table`');
      expect(unescapeText('`table`'), 'table');
      expect(unescapeText('\'table\''), 'table');
    });

    test('getNextToken', () {
      var parser = SqlParser('test');
      expect(parser.getNextToken(), 'test');

      parser = SqlParser(' test');
      expect(parser.getNextToken(), 'test');

      parser = SqlParser('test 2');
      expect(parser.getNextToken(skip: true), 'test');
      expect(parser.getNextToken(skip: true), '2');
      expect(parser.atEnd(), isTrue);

      var index = SqlParserIndex();
      parser = SqlParser('test 2');
      expect(parser.getNextToken(index: index), 'test');
      expect(index.position, 4);
      expect(parser.getNextToken(index: index), '2');
      expect(index.position, 6);

      parser = SqlParser('test;');
      index = SqlParserIndex();
      expect(parser.getNextToken(index: index), 'test');
      expect(index.position, 4);
    });

    test('parseTokens', () {
      var parser = SqlParser('test');
      expect(parser.parseTokens(['TeSt']), isTrue);
      parser = SqlParser('test 2');
      expect(parser.parseTokens(['test', '2']), isTrue);
    });

    test('parseStatements1', () {
      var statements = parseStatements('SELECT;');
      expect(statements, ['SELECT;']);
    });

    test('parseStatements1nl', () {
      var statements = parseStatements('SELECT;\n');
      expect(statements, ['SELECT;']);
    });

    test('parseStatements1emptytext', () {
      var statements = parseStatements("'';\n");
      expect(statements, ["'';"]);
    });

    test('parseStatements2', () {
      var statements = parseStatements('SELECT;SELECT;');
      expect(statements, ['SELECT;', 'SELECT;']);
    });

    test('parseStatements4', () {
      var statements = parseStatements('SELECT;\nSELECT;');
      expect(statements, ['SELECT;', 'SELECT;']);
    });

    test('parseStatements6', () {
      var statements = parseStatements('SELECT;\nSELECT;\n');
      expect(statements, ['SELECT;', 'SELECT;']);
    });

    test('parseStatements5', () {
      var statements = parseStatements('SELECT;\nSELECT;\nSELECT;');
      expect(statements, ['SELECT;', 'SELECT;', 'SELECT;']);
    });

    test('parseStatements3', () {
      var sql = '''
S;
'';
''';
      var statements = parseStatements(sql);
      expect(statements, ['S;', "'';"]);
    });
  });
}
