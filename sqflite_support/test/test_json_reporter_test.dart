import 'package:sqflite_support/sqflite_suite_run.dart';
import 'package:test/test.dart';

/// A `flutter test -r json` output: build lines, hidden loading and
/// setUpAll tests, a pass, a skip, a failure and an error.
const _output = r'''
Running Gradle task 'assembleDebug'...                             11.5s
{"protocolVersion":"0.1.1","runnerVersion":"1.31.1","pid":1,"type":"start","time":0}
{"test":{"id":1,"name":"loading integration_test/all_test.dart","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null}},"type":"testStart","time":1}
{"testID":1,"result":"success","skipped":false,"hidden":true,"type":"testDone","time":2}
{"test":{"id":2,"name":"(setUpAll)","suiteID":0,"groupIDs":[2],"metadata":{"skip":false,"skipReason":null}},"type":"testStart","time":3}
{"testID":2,"result":"success","skipped":false,"hidden":true,"type":"testDone","time":4}
{"test":{"id":3,"name":"exception Transaction failed","suiteID":0,"groupIDs":[2],"metadata":{"skip":false,"skipReason":null}},"type":"testStart","time":5}
{"testID":3,"messageType":"print","message":"native_error: DatabaseException(...)","type":"print","time":6}
{"testID":3,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":7}
{"test":{"id":4,"name":"exception Dead lock","suiteID":0,"groupIDs":[2],"metadata":{"skip":true,"skipReason":null}},"type":"testStart","time":8}
{"testID":4,"result":"success","skipped":true,"hidden":false,"type":"testDone","time":9}
{"test":{"id":5,"name":"exception constraint","suiteID":0,"groupIDs":[2],"metadata":{"skip":false,"skipReason":null}},"type":"testStart","time":10}
{"testID":5,"error":"Expected: 1555\n  Actual: 19","stackTrace":"","isFailure":true,"type":"error","time":11}
{"testID":5,"error":"second error","stackTrace":"","isFailure":true,"type":"error","time":11}
{"testID":5,"result":"failure","skipped":false,"hidden":false,"type":"testDone","time":12}
{"test":{"id":6,"name":"open crash","suiteID":0,"groupIDs":[2],"metadata":{"skip":false,"skipReason":null}},"type":"testStart","time":13}
{"testID":6,"error":"Bad state: boom","stackTrace":"","isFailure":false,"type":"error","time":14}
{"testID":6,"result":"error","skipped":false,"hidden":false,"type":"testDone","time":15}
{"success":false,"type":"done","time":16}
''';

void main() {
  group('test_json_reporter', () {
    test('summary', () {
      var summary = testJsonReporterParseLines(_output.split('\n'));
      expect(summary.passed, 1);
      expect(summary.skipped, 1);
      expect(summary.failed, 2);
      expect(summary.done, isFalse);
      expect(summary.isSuccess, isFalse);
      expect(summary.failures.map((failure) => failure.toString()), [
        'exception constraint: Expected: 1555\n  Actual: 19',
        'open crash: Bad state: boom',
      ]);
      expect(summary.toString(), '1 passed, 1 skipped, 2 failed');
    });

    test('live', () {
      var parser = TestJsonReporterParser();
      var done = [for (var line in _output.split('\n')) ?parser.addLine(line)];
      expect(done.map((test) => '${test.name} ${test.result}'), [
        'exception Transaction failed success',
        'exception Dead lock success',
        'exception constraint failure',
        'open crash error',
      ]);
      expect(done.map((test) => test.skipped), [false, true, false, false]);
    });

    test('success and incomplete runs', () {
      var lines = _output
          .split('\n')
          .where(
            (line) =>
                !line.contains('"testID":5') && !line.contains('"testID":6'),
          )
          .map((line) => line.replaceAll('"success":false', '"success":true'))
          .toList();
      var summary = testJsonReporterParseLines(lines);
      expect(summary.isSuccess, isTrue);
      expect(summary.toString(), '1 passed, 1 skipped, 0 failed');

      // Killed before the end: no done event.
      summary = testJsonReporterParseLines(lines.take(9));
      expect(summary.done, isNull);
      expect(summary.isSuccess, isFalse);
      expect(
        summary.toString(),
        '1 passed, 0 skipped, 0 failed (run not done)',
      );

      expect(testJsonReporterParseLines(['not json', '{"broken']).done, isNull);
    });
  });
}
