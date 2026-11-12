import 'dart:convert';

/// A failed test of a json reporter output.
class TestJsonFailure {
  /// The full name of the test (groups included).
  final String name;

  /// The first error reported for the test, `null` when none was.
  final String? error;

  /// A failure of the test [name] with its first [error].
  TestJsonFailure(this.name, this.error);

  @override
  String toString() => error == null ? name : '$name: $error';
}

/// A test done of a json reporter output, see [TestJsonReporterParser.addLine].
class TestJsonTestDone {
  /// The full name of the test (groups included).
  final String name;

  /// `success`, `failure` (an expectation) or `error` (an exception).
  final String result;

  /// `true` when the test was skipped.
  final bool skipped;

  /// The first error reported for the test, `null` when none was.
  final String? error;

  /// The test [name] done with [result], [skipped] or not, its first [error].
  TestJsonTestDone({
    required this.name,
    required this.result,
    required this.skipped,
    this.error,
  });

  /// `true` when the test failed (`failure` or `error`).
  bool get isFailure => result != 'success';
}

/// The counts of a json reporter output, see [TestJsonReporterParser].
class TestJsonSummary {
  /// The tests passed (skipped ones excluded).
  final int passed;

  /// The tests failed (`failure` or `error`).
  final int failed;

  /// The tests skipped.
  final int skipped;

  /// The failed tests, in their order.
  final List<TestJsonFailure> failures;

  /// The `success` of the `done` event, `null` when the run did not end
  /// (crash, killed, no json output).
  final bool? done;

  /// The [passed], [failed] and [skipped] counts, the [failures] and the
  /// [done] success of a run.
  TestJsonSummary({
    required this.passed,
    required this.failed,
    required this.skipped,
    required this.failures,
    required this.done,
  });

  /// `true` when the run ended with success, no failure and at least one
  /// test passed.
  bool get isSuccess => done == true && failed == 0 && passed > 0;

  @override
  String toString() =>
      '$passed passed, $skipped skipped, $failed failed'
      '${done == null ? ' (run not done)' : ''}';
}

/// Parses the output of `dart test` or `flutter test` with `-r json`, line
/// by line (other lines, a build output, are ignored).
///
/// Hidden tests (loading, `setUpAll`, `tearDownAll`) are not counted.
class TestJsonReporterParser {
  final _names = <int, String>{};
  final _errors = <int, String>{};
  var _passed = 0;
  var _failed = 0;
  var _skipped = 0;
  final _failures = <TestJsonFailure>[];
  bool? _done;

  /// Returns `true` when [line] is a json reporter event.
  static bool isJsonEvent(String line) => line.startsWith('{"');

  /// Parses one [line] of the output.
  ///
  /// Returns the test done when [line] ends a visible test, `null`
  /// otherwise (another event, not a json line).
  TestJsonTestDone? addLine(String line) {
    if (!isJsonEvent(line)) {
      return null;
    }
    Object? event;
    try {
      event = jsonDecode(line);
    } on FormatException catch (_) {
      return null;
    }
    if (event is! Map) {
      return null;
    }
    switch (event['type']) {
      case 'testStart':
        var test = event['test'];
        if (test is Map && test['id'] is int) {
          _names[test['id'] as int] = test['name']?.toString() ?? '';
        }
      case 'error':
        var id = event['testID'];
        var error = event['error']?.toString() ?? '';
        if (id is int) {
          _errors.putIfAbsent(id, () => error);
        }
      case 'testDone':
        var id = event['testID'];
        if (id is! int || event['hidden'] == true) {
          return null;
        }
        var done = TestJsonTestDone(
          name: _names[id] ?? 'test $id',
          result: event['result']?.toString() ?? 'error',
          skipped: event['skipped'] == true,
          error: _errors[id],
        );
        if (done.isFailure) {
          _failed++;
          _failures.add(TestJsonFailure(done.name, done.error));
        } else if (done.skipped) {
          _skipped++;
        } else {
          _passed++;
        }
        return done;
      case 'done':
        _done = event['success'] == true;
    }
    return null;
  }

  /// The counts of the lines parsed so far.
  TestJsonSummary get summary => TestJsonSummary(
    passed: _passed,
    failed: _failed,
    skipped: _skipped,
    failures: List.of(_failures),
    done: _done,
  );
}

/// Parses all the [lines] of a json reporter output, see
/// [TestJsonReporterParser].
TestJsonSummary testJsonReporterParseLines(Iterable<String> lines) {
  var parser = TestJsonReporterParser();
  for (var line in lines) {
    parser.addLine(line);
  }
  return parser.summary;
}
