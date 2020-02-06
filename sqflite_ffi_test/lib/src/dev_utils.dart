import 'env_utils.dart';
export 'package:meta/meta.dart';
export 'env_utils.dart';

/// Development helpers to generate warning in code

void _devPrint(Object object) {
  if (_devPrintEnabled) {
    print(object);
  }
}

bool _devPrintEnabled = true;

@deprecated
set devPrintEnabled(bool enabled) => _devPrintEnabled = enabled;

/// Deprecated to prevent keeping the code used.
@deprecated
void devPrint(Object object) {
  if (_devPrintEnabled) {
    print(object);
  }
}

/// Deprecated to prevent keeping the code used.
///
/// Can be use as a todo for weird code. int value = devWarning(myFunction());
/// The function is always called
@deprecated
T devWarning<T>(T value) => value;

void _devError([Object object]) {
  // one day remove the print however sometimes the error thrown is hidden
  try {
    throw UnsupportedError('$object');
  } catch (e, st) {
    if (_devPrintEnabled) {
      print('# ERROR $object');
      print(st);
    }
    rethrow;
  }
}

/// Deprecated to prevent keeping the code used.
///
/// Will call the action on debug only
@deprecated
T devDebugOnly<T>(T Function() action, {String message}) {
  if (isDebug) {
    print(
        '[DEBUG_ONLY]${message != null ? ' $message' : ' debug only behavior'}');
    return action();
  } else {
    return null;
  }
}

@deprecated
void devError([Object object]) => _devError(object);

// exported for testing
void debugDevPrint(Object object) => _devPrint(object);

void debugDevError(Object object) => _devError(object);

set debugDevPrintEnabled(bool enabled) => _devPrintEnabled = enabled;
