import 'dart:convert';
import 'dart:io';

import 'package:dev_build/shell.dart';
import 'package:path/path.dart';

/// An exp1 app variant.
class Exp1Variant {
  /// Name used on the command line.
  final String name;

  /// Package folder, in the exp1 folder.
  final String dirName;

  /// Supported platforms (`flutter create --platforms` names).
  final Set<String> platforms;

  /// Fixed web port: IndexedDB is per origin (port included), a random port
  /// would lose the data at each launch.
  final int? webPort;

  /// Variant [name] in [dirName].
  const Exp1Variant(this.name, this.dirName, this.platforms, {this.webPort});

  /// Package folder.
  String get dir => join(exp1Dir, dirName);

  @override
  String toString() => name;
}

/// The variants.
const exp1Variants = [
  Exp1Variant('sqflite', 'exp1_sqflite', {'android', 'ios', 'macos'}),
  Exp1Variant('sqflite_ffi', 'exp1_sqflite_ffi', {
    'android',
    'ios',
    'macos',
    'linux',
    'windows',
  }),
  Exp1Variant('web', 'exp1_web', {'web'}, webPort: 8761),
  Exp1Variant('merged', 'exp1_app', {
    'android',
    'ios',
    'macos',
    'linux',
    'windows',
    'web',
  }, webPort: 8764),
];

/// The variant named [name].
Exp1Variant exp1Variant(String name) => exp1Variants.firstWhere(
  (variant) => variant.name == name,
  orElse: () => throw ArgumentError.value(
    name,
    'variant',
    'one of ${exp1Variants.join(', ')}',
  ),
);

/// The exp1 folder, found from the current directory or the script.
String get exp1Dir {
  for (var start in [
    Directory.current.path,
    dirname(Platform.script.toFilePath()),
  ]) {
    var dir = normalize(absolute(start));
    while (true) {
      if (File(join(dir, 'exp1_common', 'pubspec.yaml')).existsSync()) {
        return dir;
      }
      var parent = dirname(dir);
      if (parent == dir) {
        break;
      }
      dir = parent;
    }
  }
  throw StateError('exp1 folder not found');
}

/// The host desktop device id (also its platform).
String get hostDeviceId {
  if (Platform.isLinux) {
    return 'linux';
  } else if (Platform.isMacOS) {
    return 'macos';
  } else if (Platform.isWindows) {
    return 'windows';
  }
  throw UnsupportedError('No desktop host');
}

/// A connected device of `flutter devices --machine`.
class Exp1Device {
  /// Device id.
  final String id;

  /// Device name.
  final String name;

  /// Platform: android, ios, macos, linux, windows or web.
  final String platform;

  Exp1Device._(this.id, this.name, this.platform);

  @override
  String toString() => '$id ($platform)';
}

/// Connected devices.
Future<List<Exp1Device>> exp1Devices() async {
  var result = await Shell(verbose: false).run('flutter devices --machine');
  var json = result.outText;
  var start = json.indexOf('[');
  var devices = <Exp1Device>[];
  for (var device in (jsonDecode(json.substring(start)) as List).cast<Map>()) {
    var target = device['targetPlatform'] as String? ?? '';
    String? platform;
    if (target.startsWith('android')) {
      platform = 'android';
    } else if (target.startsWith('ios')) {
      platform = 'ios';
    } else if (target.startsWith('darwin')) {
      platform = 'macos';
    } else if (target.startsWith('linux')) {
      platform = 'linux';
    } else if (target.startsWith('windows')) {
      platform = 'windows';
    } else if (target.startsWith('web')) {
      platform = 'web';
    }
    if (platform != null) {
      devices.add(
        Exp1Device._(
          device['id'] as String,
          device['name'] as String? ?? '',
          platform,
        ),
      );
    }
  }
  return devices;
}

/// Creates the [platform] project of [variant] if missing (platform folders
/// are not checked in) and the sqflite web binaries for the web.
Future<void> exp1PrepareVariant(Exp1Variant variant, String platform) async {
  var shell = Shell(workingDirectory: variant.dir);
  if (!Directory(join(variant.dir, platform)).existsSync()) {
    await shell.run(
      'flutter create --org com.tekartik.exp1 --platforms $platform .',
    );
    // flutter create adds a counter test referencing a missing MyApp.
    var counterTest = File(join(variant.dir, 'test', 'widget_test.dart'));
    if (counterTest.existsSync() &&
        counterTest.readAsStringSync().contains('MyApp')) {
      counterTest.deleteSync();
      var testDir = counterTest.parent;
      if (testDir.listSync().isEmpty) {
        testDir.deleteSync();
      }
    }
  }
  if (platform == 'web' &&
      !File(join(variant.dir, 'web', 'sqflite_sw.js')).existsSync()) {
    await shell.run('dart run sqflite_common_ffi_web:setup');
  }
}
