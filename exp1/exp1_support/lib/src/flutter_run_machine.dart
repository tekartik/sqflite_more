import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dev_build/shell.dart';

/// Decodes a `flutter run --machine` stdout line: a JSON array with one
/// event or response, null for any other output.
Map<String, Object?>? decodeFlutterMachineLine(String line) {
  line = line.trim();
  if (!line.startsWith('[{') || !line.endsWith('}]')) {
    return null;
  }
  try {
    var decoded = jsonDecode(line);
    if (decoded is List && decoded.length == 1 && decoded.first is Map) {
      return (decoded.first as Map).cast<String, Object?>();
    }
  } on FormatException catch (_) {}
  return null;
}

/// A debug app launched with `flutter run --machine`, controlled through the
/// daemon protocol on stdin/stdout: hot restart and stop.
class FlutterRunMachine {
  /// App package folder.
  final String appDir;

  /// Device id (`linux`, `chrome`, `emulator-5554`...).
  final String deviceId;

  /// Extra `flutter run` arguments.
  final List<String> arguments;

  /// Prints the app logs and the daemon progress.
  final bool verbose;

  late final Process _process;
  final _started = Completer<void>();
  final _debugPort = Completer<void>();
  final _exited = Completer<int>();
  final _pending = <int, Completer<Object?>>{};
  var _nextId = 1;
  String? _appId;
  String? _vmServiceUri;

  FlutterRunMachine._({
    required this.appDir,
    required this.deviceId,
    required this.arguments,
    required this.verbose,
  });

  /// The VM service (web socket) of the app, known once started.
  String get vmServiceUri =>
      _vmServiceUri ?? (throw StateError('No VM service uri'));

  /// Launches the app and waits until it is started (first build included).
  static Future<FlutterRunMachine> start({
    required String appDir,
    required String deviceId,
    List<String> arguments = const [],
    bool verbose = false,
    Duration timeout = const Duration(minutes: 15),
  }) async {
    var run = FlutterRunMachine._(
      appDir: appDir,
      deviceId: deviceId,
      arguments: arguments,
      verbose: verbose,
    );
    await run._start(timeout);
    return run;
  }

  void _log(String message) {
    if (verbose) {
      stdout.writeln('  | $message');
    }
  }

  Future<void> _start(Duration timeout) async {
    var flutter = flutterExecutablePath ?? 'flutter';
    var args = ['run', '--machine', '-d', deviceId, ...arguments];
    _log('${shellArgument(flutter)} ${shellArguments(args)}');
    _process = await Process.start(
      flutter,
      args,
      workingDirectory: appDir,
      runInShell: Platform.isWindows,
    );
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine);
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _log('stderr: $line'));
    unawaited(
      _process.exitCode.then((code) {
        _exited.complete(code);
        if (!_started.isCompleted) {
          _started.completeError(
            StateError('flutter run exited ($code) before the app started'),
          );
        }
        for (var completer in _pending.values) {
          completer.completeError(StateError('flutter run exited ($code)'));
        }
        _pending.clear();
      }),
    );
    await _started.future.timeout(timeout);
    // On the web the debug port event comes after app.started.
    await _debugPort.future.timeout(const Duration(minutes: 1));
  }

  void _onLine(String line) {
    var message = decodeFlutterMachineLine(line);
    if (message == null) {
      _log(line);
      return;
    }
    var id = message['id'];
    if (id is int) {
      var completer = _pending.remove(id);
      var error = message['error'];
      if (error != null) {
        completer?.completeError(StateError('$error'));
      } else {
        completer?.complete(message['result']);
      }
      return;
    }
    var params = (message['params'] as Map?)?.cast<String, Object?>() ?? {};
    switch (message['event']) {
      case 'app.start':
        _appId = params['appId'] as String?;
      case 'app.debugPort':
        _vmServiceUri = params['wsUri'] as String?;
        if (!_debugPort.isCompleted) {
          _debugPort.complete();
        }
      case 'app.started':
        if (!_started.isCompleted) {
          _started.complete();
        }
      case 'app.log':
        _log('app: ${params['log']}');
      case 'app.progress':
        var progress = params['message'];
        if (progress != null) {
          _log('$progress');
        }
      case 'daemon.logMessage':
        _log('${params['level']}: ${params['message']}');
    }
  }

  Future<Object?> _request(String method, Map<String, Object?> params) {
    var id = _nextId++;
    var completer = _pending[id] = Completer<Object?>();
    _process.stdin.writeln(
      jsonEncode([
        {'id': id, 'method': method, 'params': params},
      ]),
    );
    return completer.future;
  }

  /// Hot restart: the Dart state is reset and `main()` runs again in the same
  /// process.
  Future<void> hotRestart() async {
    var result = await _request('app.restart', {
      'appId': _appId,
      'fullRestart': true,
      'pause': false,
    });
    if (result is Map && result['code'] != 0) {
      throw StateError('Hot restart failed: ${result['message']}');
    }
  }

  /// Stops the app and `flutter run`.
  Future<void> stop() async {
    if (_exited.isCompleted) {
      return;
    }
    try {
      await _request('app.stop', {
        'appId': _appId,
      }).timeout(const Duration(seconds: 30));
    } catch (e) {
      _log('stop: $e');
    }
    try {
      await _exited.future.timeout(const Duration(seconds: 30));
    } on TimeoutException catch (_) {
      _process.kill();
      await _exited.future;
    }
  }
}
