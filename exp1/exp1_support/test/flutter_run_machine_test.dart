import 'package:sqflite_exp1_support/exp1_support.dart';
import 'package:test/test.dart';

void main() {
  test('decodeFlutterMachineLine', () {
    expect(
      decodeFlutterMachineLine(
        '[{"event":"app.debugPort","params":{"appId":"a","wsUri":"ws://x/ws"}}]',
      ),
      {
        'event': 'app.debugPort',
        'params': {'appId': 'a', 'wsUri': 'ws://x/ws'},
      },
    );
    expect(decodeFlutterMachineLine('[{"id":1,"result":{"code":0}}]'), {
      'id': 1,
      'result': {'code': 0},
    });
    expect(decodeFlutterMachineLine('Launching lib/main.dart'), isNull);
    expect(decodeFlutterMachineLine('[{not json}]'), isNull);
  });
  test('variants', () {
    expect(exp1Variant('merged').dirName, 'exp1_app');
    expect(exp1Variant('web').platforms, {'web'});
    expect(() => exp1Variant('unknown'), throwsArgumentError);
  });
}
