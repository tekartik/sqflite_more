import 'dart:io';

/// Add sqflite dependencies in a brut force way
String pubspecStringAddSqflite(String content) {
  if (!content.contains('sqflite')) {
    return content.replaceAllMapped(
      RegExp(r'^dependencies:$', multiLine: true),
      (match) => 'dependencies:\n  sqflite:',
    );
  }
  return content;
}

/// Desktop init no longer needed
Future initFlutter() async {
  /*
  _flutterChannel = await getFlutterBinChannel();
  if (supportsMacOS) {
    await run('flutter config --enable-macos-desktop');
  }
  if (supportsLinux) {
    await run('flutter config --enable-linux-desktop');
  }
  if (supportsWindows) {
    await run('flutter config --enable-windows-desktop');
  }*/
}

bool get supportsMacOS => Platform.isMacOS;

bool get supportsLinux => Platform.isLinux;

bool get supportsWindows => Platform.isWindows;
