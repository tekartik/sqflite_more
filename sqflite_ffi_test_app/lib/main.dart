import 'package:flutter/material.dart';

/// The app is a host for the test runners (integration_test, test_web), see
/// the README.
void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('sqflite_common_ffi test app, see integration_test'),
        ),
      ),
    ),
  );
}
