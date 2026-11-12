import 'dart:convert';

import 'package:sqflite_support/sqflite_suite_run.dart';
import 'package:test/test.dart';

Map<String, Object?> _device(
  String udid,
  String name, {
  String state = 'Shutdown',
  String? type,
  bool isAvailable = true,
}) => {
  'udid': udid,
  'name': name,
  'state': state,
  'isAvailable': isAvailable,
  'deviceTypeIdentifier': ?type,
};

String _json(Map<String, List<Map<String, Object?>>> devices) =>
    jsonEncode({'devices': devices});

void main() {
  group('iosSimulatorRuntimeVersion', () {
    test('ios', () {
      expect(
        iosSimulatorRuntimeVersion(
          'com.apple.CoreSimulator.SimRuntime.iOS-27-0',
        ),
        [27, 0],
      );
      expect(
        iosSimulatorRuntimeVersion(
          'com.apple.CoreSimulator.SimRuntime.iOS-18-4',
        ),
        [18, 4],
      );
    });
    test('not ios', () {
      expect(
        iosSimulatorRuntimeVersion(
          'com.apple.CoreSimulator.SimRuntime.watchOS-11-0',
        ),
        isEmpty,
      );
      expect(
        iosSimulatorRuntimeVersion('com.apple.CoreSimulator.SimRuntime.iOS-x'),
        isEmpty,
      );
    });
  });

  group('iosSimulatorsParseJson', () {
    test('latest runtime first, other platforms and unavailable skipped', () {
      var simulators = iosSimulatorsParseJson(
        _json({
          'com.apple.CoreSimulator.SimRuntime.iOS-18-4': [
            _device('A', 'iPhone 16'),
          ],
          'com.apple.CoreSimulator.SimRuntime.watchOS-11-0': [
            _device('W', 'Apple Watch'),
          ],
          'com.apple.CoreSimulator.SimRuntime.iOS-27-0': [
            _device('B', 'iPhone 18 Pro'),
            _device('C', 'iPhone 17', isAvailable: false),
            _device('D', 'iPad (A16)'),
          ],
          'com.apple.CoreSimulator.SimRuntime.iOS-26-5': [
            _device('E', 'iPhone 17', state: 'Booted'),
          ],
        }),
      );
      expect(simulators.map((s) => s.udid), ['B', 'D', 'E', 'A']);
      expect(simulators[2].isBooted, isTrue);
      expect(simulators[2].iosVersion, [26, 5]);
    });
  });

  group('iosSimulatorChooseTarget', () {
    var simulators = iosSimulatorsParseJson(
      _json({
        'com.apple.CoreSimulator.SimRuntime.iOS-27-0': [
          _device(
            'IPAD',
            'iPad (A16)',
            type: 'com.apple.CoreSimulator.SimDeviceType.iPad-A16',
          ),
          _device(
            'P27',
            'iPhone 17',
            type: 'com.apple.CoreSimulator.SimDeviceType.iPhone-17',
          ),
        ],
        'com.apple.CoreSimulator.SimRuntime.iOS-26-5': [
          _device('P26', 'iPhone 17'),
          _device('AIR', 'iPhone Air'),
        ],
      }),
    );
    test('default: first iPhone of the latest runtime', () {
      expect(iosSimulatorChooseTarget(simulators).udid, 'P27');
    });
    test('default: booted first', () {
      var withBooted = [
        ...simulators,
        IosSimulator(
          udid: 'BOOTED',
          name: 'iPad mini',
          runtime: 'com.apple.CoreSimulator.SimRuntime.iOS-18-4',
          state: iosSimulatorStateBooted,
        ),
      ];
      expect(iosSimulatorChooseTarget(withBooted).udid, 'BOOTED');
      // A name or UDID given wins over the booted one.
      expect(
        iosSimulatorChooseTarget(withBooted, simulator: 'iPhone Air').udid,
        'AIR',
      );
    });
    test('by udid', () {
      expect(
        iosSimulatorChooseTarget(simulators, simulator: 'p26').udid,
        'P26',
      );
    });
    test('by name: booted first, else latest runtime', () {
      expect(
        iosSimulatorChooseTarget(simulators, simulator: 'iPhone 17').udid,
        'P27',
      );
      var withBooted = simulators
          .map(
            (s) => s.udid == 'P26'
                ? IosSimulator(
                    udid: s.udid,
                    name: s.name,
                    runtime: s.runtime,
                    state: iosSimulatorStateBooted,
                  )
                : s,
          )
          .toList();
      expect(
        iosSimulatorChooseTarget(withBooted, simulator: 'iPhone 17').udid,
        'P26',
      );
    });
    test('not found', () {
      expect(
        () => iosSimulatorChooseTarget(simulators, simulator: 'Pixel 9'),
        throwsStateError,
      );
      expect(() => iosSimulatorChooseTarget([]), throwsStateError);
    });
  });
}
