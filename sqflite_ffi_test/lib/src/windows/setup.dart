import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:moor_ffi/open_helper.dart';
import 'package:path/path.dart';

String _findPackage(String currentPath) {
  String findPath(File file) {
    var lines = LineSplitter.split(file.readAsStringSync());
    for (var line in lines) {
      var parts = line.split(':');
      if (parts.length > 1) {
        if (parts[0] == 'sqflite_ffi_test') {
          var location = parts[1];
          if (isRelative(location)) {
            return join(dirname(file.path), location);
          }
          return location;
        }
      }
    }
    return null;
  }

  var file = File(join(currentPath, '.packages'));
  if (file.existsSync()) {
    return findPath(file);
  } else {
    var parent = dirname(currentPath);
    if (parent == currentPath) {
      return null;
    }
    return _findPackage(parent);
  }


}

/// One windows load the embedded sqlite3.dll for convenience
void windowsInit() {
  var location = _findPackage(Directory.current.path);
  var path = normalize(join(location, 'src', 'windows', 'sqlite3.dll'));
  open.overrideFor(OperatingSystem.windows, () {
    // print('loading $path');
    return DynamicLibrary.open(path);
  });

  // sqflite_ffi_test:lib/
}
