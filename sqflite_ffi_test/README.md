# sqflite_ffi_test

sqflite dev testing using ffi. Based on [`moor_ffi`](https://pub.dev/packages/moor_ffi). Thanks to [Simon Binder](https://github.com/simolus3)

It allows mocking sqflite during regular flutter unit test.
One goal is make it stricter than sqflite to encourage good practices.

Currently supported on Linux.

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
    version: '>=0.0.1'
```

### Linux

`sqlite3` and `sqlite3-dev` linux packages are required.

```bash
dart tool/setup.dart
```

## Simple code

main.dart:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_ffi_test/sqflite_ffi_test.dart';

void main() {
  // Set sqflite ffi support in test
  TestWidgetsFlutterBinding.ensureInitialized();
  setAsMockMethodCallHandler();

  test('simple sqflite example', () async {
    var db = await openDatabase(inMemoryDatabasePath);
    expect(await db.getVersion(), 0);
    await db.close();
  });
}
```
## Limitations

* Only `Uint8List` is accepted for bloc since `List<int>` is not optimized
* read-only support is limited and faked so some command might still
 work (such as `PRAGMA user_version = 4`), insert, update, delete will be prevented through
* Multi-instance support (not common) is simulated