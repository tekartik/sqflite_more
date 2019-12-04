import 'fetch_sqflite_example.dart';

Future main() async {
  await sparseCheckout(
      dir: 'tmp/sdk_samples_ffi_sqlite',
      url: 'git@github.com:dart-lang/sdk.git',
      remoteDirs: ['samples/ffi/sqlite']);
}
