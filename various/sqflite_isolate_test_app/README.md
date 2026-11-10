# sqflite_isolate_test_app

Test menu app using sqflite from another isolate with
[flutter_isolate](https://pub.dev/packages/flutter_isolate) (Android, iOS):
create rows in the main isolate or in a `FlutterIsolate`, then read them.

Not published.

## State

It does not build with the current Flutter:

* the `android/` and `ios/` folders date from 2019 (the Android one applies
  the Flutter Gradle plugin the old way, which Flutter now refuses);
* flutter_isolate 2.1.0, its latest version, does not compile on Android any
  more (`io.flutter.view.FlutterRunArguments` was removed from Flutter).

Using sqflite from a background isolate (`Isolate.run`, `compute`) with
`BackgroundIsolateBinaryMessenger.ensureInitialized(RootIsolateToken)` is
tested by the plugin test page of the sqflite repository's
`sqflite_test_app`; see sqflite's
[isolates](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/usage_recommendations.md#isolates)
recommendations.
