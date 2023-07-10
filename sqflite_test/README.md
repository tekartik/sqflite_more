# sqflite_test

SQFlite test package

## Getting Started

dependencies:

```yaml
  sqflite_test:
    git:
      url: https://github.com/tekartik/sqflite_more
      ref: dart3a
      path: sqflite_test
    version: '>=0.2.0'
```

## Running tests

* Start sqflite server app <https://github.com/tekartik/sqflite_more/blob/master/sqflite_server/README.md>
* (Android only) forward tcp port `adb forward tcp:8501 tcp:8501`
* Run the tests

```
flutter test
```