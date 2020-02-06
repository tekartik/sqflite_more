import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:process_run/shell_run.dart';

void main() {
  group('no_flutter', () {
    test('simple', () async {
      await run('dart test/no_flutter_main.dart',
          verbose: false, stderr: stderr);
    }, skip: 'Skipped until sqflite allows non flutter mixins');
  });
}
