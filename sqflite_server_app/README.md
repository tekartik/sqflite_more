# sqflite_server_app

A Flutter app serving its sqflite database factory over a web socket
(`sqflite_common_server`): a test on your computer (`sqflite_test`) runs its
sqflite calls against the real plugin of a device. Tested on Android.

## Run

From this folder (a package of the repository workspace):

```sh
flutter run                         # on the device or emulator
adb forward tcp:8501 tcp:8501       # Android, once per connection
```

Press START: the server listens on the port typed (8501 by default, 0 for
any free port), the page shows the port and the console the web socket
url. The port and the started state are saved: the next launch starts the
server at once until STOP is pressed. The console lists the SQL received.

Then, on the computer, the tests of
[`sqflite_test`](../sqflite_test) (`flutter test test/device_test.dart`):
it forwards the port itself on Android when `adb` is in the `PATH`.

- Platforms: Android and iOS (the runners of this folder) serve the sqflite
  plugin. On Linux and Windows the code serves sqflite_common_ffi (SQLite
  files of the computer: to try the protocol, not the plugin) once a runner
  is added (`flutter create --platforms=linux .`).
- Another port: type it before START, and give the test
  `--dart-define=SQFLITE_SERVER_PORT=<port>` (it forwards that port).
- `flutter run -t lib/test_main.dart`: a test menu (export/import with
  sqflite_porter, a server started from the menu, the home page).
- `flutter test`: the database factory (Linux, Windows) and the prefs, run
  against a server when one answers (else they pass without checking).

## dev

Launcher icon, here at 1024x1024: `assets/dev/icon/launcher-icon.png`

```sh
dart run flutter_launcher_icons
```
