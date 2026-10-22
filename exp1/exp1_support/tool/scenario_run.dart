/// Runs the exp1 scenarios on a device: the app is launched in debug with
/// `flutter run --machine` (hot restart, stop) and driven with flutter_driver
/// through its widget ids.
///
/// ```bash
/// # all the scenarios of the merged app on the host desktop
/// dart run tool/scenario_run.dart
/// # one variant, one device, some scenarios
/// dart run tool/scenario_run.dart -v sqflite -d emulator-5554 -s crud,hot-restart
/// # every variant supported by the device
/// dart run tool/scenario_run.dart -v all -d chrome
/// # variants, scenarios and devices
/// dart run tool/scenario_run.dart --list
/// ```
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:sqflite_exp1_support/exp1_support.dart';

Future<void> main(List<String> arguments) async {
  var parser = ArgParser()
    ..addOption(
      'variant',
      abbr: 'v',
      help: '${exp1Variants.join(', ')} or all',
      defaultsTo: 'merged',
    )
    ..addOption(
      'device',
      abbr: 'd',
      help: 'flutter device id (default: host desktop)',
    )
    ..addOption(
      'scenario',
      abbr: 's',
      help:
          '${exp1Scenarios.map((s) => s.name).join(', ')} or all, comma separated',
      defaultsTo: 'all',
    )
    ..addFlag('list', help: 'List variants, scenarios and devices')
    ..addFlag('verbose', help: 'Show the flutter run and app output')
    ..addFlag('help', abbr: 'h', negatable: false);
  var results = parser.parse(arguments);
  if (results.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }

  var devices = await exp1Devices();
  if (results.flag('list')) {
    stdout.writeln('Variants:');
    for (var variant in exp1Variants) {
      stdout.writeln(
        '  ${variant.name.padRight(12)} ${variant.dirName.padRight(18)} '
        '${variant.platforms.join(', ')}',
      );
    }
    stdout.writeln('Scenarios:');
    for (var scenario in exp1Scenarios) {
      stdout.writeln('  ${scenario.name.padRight(12)} ${scenario.description}');
    }
    stdout.writeln('Devices:');
    for (var device in devices) {
      stdout.writeln('  $device ${device.name}');
    }
    return;
  }

  var deviceId = results.option('device') ?? hostDeviceId;
  var device = devices.firstWhere(
    (device) => device.id == deviceId,
    orElse: () => throw ArgumentError.value(
      deviceId,
      'device',
      'not connected, one of ${devices.join(', ')}',
    ),
  );
  var variantName = results.option('variant')!;
  var variants = variantName == 'all'
      ? exp1Variants
            .where((variant) => variant.platforms.contains(device.platform))
            .toList()
      : [exp1Variant(variantName)];
  for (var variant in variants) {
    if (!variant.platforms.contains(device.platform)) {
      throw ArgumentError(
        '${variant.name} does not support ${device.platform} '
        '(${variant.platforms.join(', ')})',
      );
    }
  }
  var scenarioNames = results.option('scenario')!.split(',');
  var scenarios = scenarioNames.contains('all')
      ? exp1Scenarios
      : [
          for (var name in scenarioNames)
            exp1Scenarios.firstWhere(
              (scenario) => scenario.name == name,
              orElse: () => throw ArgumentError.value(name, 'scenario'),
            ),
        ];

  var report = <String>[];
  var failures = 0;
  for (var variant in variants) {
    stdout.writeln('== ${variant.name} on $device');
    await exp1PrepareVariant(variant, device.platform);
    var session = Exp1Session(
      variant,
      device,
      verbose: results.flag('verbose'),
    );
    try {
      await session.launch();
      for (var scenario in scenarios) {
        stdout.writeln('  -- ${scenario.name}: ${scenario.description}');
        var stopwatch = Stopwatch()..start();
        String result;
        try {
          await scenario.run(session);
          result = 'PASS';
        } catch (e) {
          failures++;
          result = 'FAIL $e';
          stdout.writeln('    $e');
          await session.screenshot(
            join(
              '.local',
              'scenario_failures',
              '${variant.name}_${device.id}_${scenario.name}.png',
            ),
          );
          // Fresh app for the next scenario
          await session.restart();
        }
        var line =
            '${variant.name.padRight(12)} ${device.id.padRight(16)} '
            '${scenario.name.padRight(12)} '
            '${(stopwatch.elapsed.inMilliseconds / 1000).toStringAsFixed(1).padLeft(6)}s $result';
        stdout.writeln('    $line');
        report.add(line);
      }
    } catch (e) {
      failures++;
      report.add(
        '${variant.name.padRight(12)} ${device.id.padRight(16)} launch FAIL $e',
      );
      stdout.writeln('  $e');
    } finally {
      await session.stop();
    }
  }
  stdout.writeln('\nReport:');
  for (var line in report) {
    stdout.writeln('  $line');
  }
  exit(failures == 0 ? 0 : 1);
}
