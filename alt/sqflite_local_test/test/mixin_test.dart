@TestOn('vm')
import 'package:test/test.dart';
import '../../../../sqflite/sqflite/test/src_mixin_test.dart' as mixin_text;

void main() {
  group('vm', () {
    mixin_text.run();
  });
}
