import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';

/// The runtime identifier prefix of the iOS simulators.
const iosSimulatorRuntimePrefix = 'com.apple.CoreSimulator.SimRuntime.iOS-';

/// The state of a booted simulator.
const iosSimulatorStateBooted = 'Booted';

/// An iOS simulator of `xcrun simctl list devices available -j`.
class IosSimulator {
  /// Its UDID, the device id of `flutter test -d`.
  final String udid;

  /// Its name (`iPhone 17`).
  final String name;

  /// Its runtime identifier
  /// (`com.apple.CoreSimulator.SimRuntime.iOS-27-0`).
  final String runtime;

  /// `Booted`, `Shutdown`, `Booting`...
  final String state;

  /// Its device type identifier
  /// (`com.apple.CoreSimulator.SimDeviceType.iPhone-17`).
  final String? deviceType;

  /// The simulator [udid] named [name] on [runtime] in [state].
  IosSimulator({
    required this.udid,
    required this.name,
    required this.runtime,
    required this.state,
    this.deviceType,
  });

  /// `true` when booted.
  bool get isBooted => state == iosSimulatorStateBooted;

  /// `true` for an iPhone.
  bool get isIPhone =>
      deviceType?.contains('.iPhone') ?? name.startsWith('iPhone');

  /// The iOS version of [runtime] (`[27, 0]`), empty when not parsed.
  List<int> get iosVersion => iosSimulatorRuntimeVersion(runtime);

  @override
  String toString() =>
      '$name ($udid) iOS ${iosVersion.join('.')}${isBooted ? ' booted' : ''}';
}

/// The version of an iOS [runtime] identifier
/// (`com.apple.CoreSimulator.SimRuntime.iOS-27-0` → `[27, 0]`), empty when
/// not an iOS runtime.
List<int> iosSimulatorRuntimeVersion(String runtime) {
  if (!runtime.startsWith(iosSimulatorRuntimePrefix)) {
    return const [];
  }
  var parts = runtime.substring(iosSimulatorRuntimePrefix.length).split('-');
  var version = parts.map(int.tryParse).toList();
  return version.contains(null) ? const [] : version.nonNulls.toList();
}

int _compareVersions(List<int> a, List<int> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    var diff = a[i].compareTo(b[i]);
    if (diff != 0) {
      return diff;
    }
  }
  return a.length.compareTo(b.length);
}

/// The iOS simulators of the json output of
/// `xcrun simctl list devices available -j`, the latest runtime first.
List<IosSimulator> iosSimulatorsParseJson(String json) {
  var devices =
      (jsonDecode(json) as Map<String, Object?>)['devices']
          as Map<String, Object?>;
  var simulators = <IosSimulator>[];
  for (var entry in devices.entries) {
    if (!entry.key.startsWith(iosSimulatorRuntimePrefix)) {
      continue;
    }
    for (var device in (entry.value as List).cast<Map<String, Object?>>()) {
      if (device['isAvailable'] == false) {
        continue;
      }
      simulators.add(
        IosSimulator(
          udid: device['udid'] as String,
          name: device['name'] as String,
          runtime: entry.key,
          state: device['state'] as String,
          deviceType: device['deviceTypeIdentifier'] as String?,
        ),
      );
    }
  }
  // Stable sort: the latest runtime first, simctl order kept within one.
  var indexed = simulators.indexed.toList()
    ..sort((a, b) {
      var diff = _compareVersions(b.$2.iosVersion, a.$2.iosVersion);
      return diff != 0 ? diff : a.$1.compareTo(b.$1);
    });
  return indexed.map((e) => e.$2).toList();
}

/// The available iOS simulators (`xcrun simctl list devices available -j`),
/// the latest runtime first.
Future<List<IosSimulator>> listIosSimulators() async {
  var result = await Shell(verbose: false).runExecutableArguments('xcrun', [
    'simctl',
    'list',
    'devices',
    'available',
    '-j',
  ]);
  return iosSimulatorsParseJson(result.outText);
}

/// Chooses the simulator to run on among [simulators] (latest runtime
/// first, [listIosSimulators]):
///
/// - [simulator] given: the one of this UDID, else the one of this name
///   (booted first, else on the latest runtime),
/// - else the first booted one,
/// - else the first iPhone of the latest runtime.
///
/// Throws a [StateError] when none matches.
IosSimulator iosSimulatorChooseTarget(
  List<IosSimulator> simulators, {
  String? simulator,
}) {
  if (simulator != null) {
    var byUdid = simulators.where(
      (s) => s.udid.toLowerCase() == simulator.toLowerCase(),
    );
    if (byUdid.isNotEmpty) {
      return byUdid.first;
    }
    var byName = simulators.where((s) => s.name == simulator).toList();
    if (byName.isEmpty) {
      throw StateError(
        'iOS simulator $simulator not found, available: '
        '${simulators.map((s) => s.name).toSet().join(', ')}',
      );
    }
    return byName.firstWhere((s) => s.isBooted, orElse: () => byName.first);
  }
  var booted = simulators.where((s) => s.isBooted);
  if (booted.isNotEmpty) {
    return booted.first;
  }
  var iPhones = simulators.where((s) => s.isIPhone);
  if (iPhones.isEmpty) {
    throw StateError(
      'No iOS simulator available (create one in DeviceHub or with '
      'xcrun simctl create)',
    );
  }
  return iPhones.first;
}

/// The path of the simulator app of the selected Xcode: `DeviceHub.app`
/// (Xcode 27+) or `Simulator.app`, `null` when not found.
Future<String?> getIosSimulatorAppPath() async {
  var result = await Shell(
    verbose: false,
    throwOnError: false,
  ).runExecutableArguments('xcode-select', ['-p']);
  var developerPath = result.outText.trim();
  if (result.exitCode != 0 || developerPath.isEmpty) {
    return null;
  }
  for (var path in [
    join(dirname(developerPath), 'Applications', 'DeviceHub.app'),
    join(developerPath, 'Applications', 'Simulator.app'),
  ]) {
    if (Directory(path).existsSync()) {
      return path;
    }
  }
  return null;
}

/// Boots the simulator [udid] and waits until its boot is completed
/// (`xcrun simctl bootstatus -b`), then shows it in DeviceHub (or
/// Simulator) unless [noWindow].
///
/// Throws a [TimeoutException] when not booted after [bootTimeout] (the
/// simulator being shut down first).
Future<void> bootIosSimulator(
  String udid, {
  bool noWindow = false,
  Duration bootTimeout = const Duration(minutes: 5),
}) async {
  var shell = Shell(verbose: false, commandVerbose: true);
  try {
    await shell
        .runExecutableArguments('xcrun', ['simctl', 'bootstatus', udid, '-b'])
        .timeout(bootTimeout);
  } on TimeoutException {
    await shutdownIosSimulator(udid);
    rethrow;
  }
  if (!noWindow) {
    await showIosSimulatorApp();
  }
}

/// Opens DeviceHub (or Simulator) showing the booted simulators, ignored
/// when not found.
Future<void> showIosSimulatorApp() async {
  var appPath = await getIosSimulatorAppPath();
  if (appPath == null) {
    return;
  }
  await Shell(
    verbose: false,
    commandVerbose: true,
    throwOnError: false,
  ).runExecutableArguments('open', ['-a', appPath]);
}

/// Shuts the simulator [udid] down (`xcrun simctl shutdown`).
Future<void> shutdownIosSimulator(String udid) async {
  await Shell(
    verbose: false,
    commandVerbose: true,
    throwOnError: false,
  ).runExecutableArguments('xcrun', ['simctl', 'shutdown', udid]);
}

/// The simulator given to the action of [withIosSimulator].
class IosRunSimulator {
  /// The simulator.
  final IosSimulator simulator;

  /// `true` when [withIosSimulator] booted it.
  final bool launched;

  /// The [simulator], [launched] or not.
  IosRunSimulator({required this.simulator, this.launched = false});

  /// Its UDID, the device id of `flutter test -d`.
  String get udid => simulator.udid;

  @override
  String toString() => '$simulator${launched ? ' launched' : ''}';
}

/// Runs [action] on a booted iOS simulator: the one chosen by
/// [iosSimulatorChooseTarget] from [simulator] (a UDID or a name), booted
/// when needed, then shut down unless [keep] when it was booted for it.
///
/// [noWindow] does not open DeviceHub on a boot (headless, the simulator
/// runs all the same). [onLaunching] is called with the simulator before
/// it is booted (to shut it down on an interruption). Returns the result of
/// [action]. Throws a [StateError] when no simulator can be chosen, a
/// [TimeoutException] when it does not boot.
Future<T> withIosSimulator<T>(
  Future<T> Function(IosRunSimulator simulator) action, {
  String? simulator,
  bool keep = false,
  bool noWindow = false,
  Duration bootTimeout = const Duration(minutes: 5),
  void Function(IosSimulator simulator)? onLaunching,
}) async {
  var target = iosSimulatorChooseTarget(
    await listIosSimulators(),
    simulator: simulator,
  );
  if (target.isBooted) {
    return await action(IosRunSimulator(simulator: target));
  }
  onLaunching?.call(target);
  await bootIosSimulator(
    target.udid,
    noWindow: noWindow,
    bootTimeout: bootTimeout,
  );
  try {
    return await action(IosRunSimulator(simulator: target, launched: true));
  } finally {
    if (!keep) {
      stdout.writeln('Shutting down ${target.name}...');
      await shutdownIosSimulator(target.udid);
    }
  }
}
