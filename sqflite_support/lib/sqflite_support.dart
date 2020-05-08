import 'dart:io';

import 'package:process_run/dartbin.dart';
import 'package:process_run/shell_run.dart';

/// Add sqflite dependencies in a brut force way
String pubspecStringAddSqflite(String content) {
  if (!content.contains('sqflite')) {
    return content.replaceAllMapped(RegExp(r'^dependencies:$', multiLine: true),
        (match) => 'dependencies:\n  sqflite:');
  }
  return content;
}

String _flutterChannel;
Future initFlutter() async {
  _flutterChannel = await getFlutterBinChannel();
  if (supportsMacOS) {
    await run('flutter config --enable-macos-desktop');
  }
}

bool get supportsMacOS =>
    Platform.isMacOS && [dartChannelDev, 'master'].contains(_flutterChannel);
