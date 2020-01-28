# sqflite ffi test

[sqflite](https://pub.dev/packages/sqflite) based source unit testing using ffi. Based on [`moor_ffi`](https://pub.dev/packages/moor_ffi). Thanks to [Simon Binder](https://github.com/simolus3)

It allows mocking sqflite during regular flutter unit test (i.e. not using the emulator/simulator).
One goal is make it stricter than sqflite to encourage good practices.

Currently supported on Linux, MacOS and Windows.

## Getting Started

### Dart

Add the following dev dependency:

```yaml
dev_dependencies:
  sqflite_ffi_test:
    git:
      url: git://github.com/tekartik/sqflite_more
      ref: dart2
      path: sqflite_ffi_test
```

### Linux

`sqlite3` and `sqlite3-dev` linux packages are required.

```bash
dart tool/linux_setup.dart
```

### MacOS

Should work as is.

### Windows

Should work as is (`sqlite3.dll` is bundled).

## Simple code

main.dart:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_ffi_test/sqflite_ffi_test.dart';

void main() {
  // Set sqflite ffi support in test
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiTestInit();

  test('simple sqflite example', () async {
    var db = await openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
}
```
## Limitations

* This is intended for mocking database calls during flutter unit test, don't use this in production.
* Database calls are made in the foreground isolate so don't make fancy lock mechanism,
* Only `Uint8List` is accepted for blob since `List<int>` is not optimized
* read-only support is limited and faked so some command might still
 work (such as `PRAGMA user_version = 4`), insert, update, delete will be prevented through
* Multi-instance support (not common) is simulated