@TestOn('vm')
import 'package:test/test.dart';
import '../../../sqflite/test/src_mixin_test_.dart' as mixin_text;

void main() {
  group('vm', () {
    mixin_text.run();
  });
}
