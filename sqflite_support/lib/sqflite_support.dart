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
  if (supportsLinux) {
    await run('flutter config --enable-linux-desktop');
  }
  if (supportsWindows) {
    await run('flutter config --enable-windows-desktop');
  }
}

bool get supportsMacOS =>
    Platform.isMacOS &&
    [dartChannelDev, dartChannelMaster].contains(_flutterChannel);

bool get supportsLinux =>
    Platform.isLinux &&
    [dartChannelDev, dartChannelMaster].contains(_flutterChannel);

bool get supportsWindows =>
    Platform.isWindows && [dartChannelMaster].contains(_flutterChannel);
