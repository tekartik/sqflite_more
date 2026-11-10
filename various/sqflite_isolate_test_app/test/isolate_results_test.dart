import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_isolate_test_app/main.dart';

void main() {
  // The result used to be read with `receivePort.first as FutureOr<String>`,
  // a cast that always throws (a Future<dynamic> is not a FutureOr<String>).
  test('readIsolateResults', () async {
    var receivePort = ReceivePort();
    receivePort.sendPort.send(
      json.encode([
        {'id': 1, 'name': 'item 1'},
      ]),
    );
    expect(await readIsolateResults(receivePort), [
      {'id': 1, 'name': 'item 1'},
    ]);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
