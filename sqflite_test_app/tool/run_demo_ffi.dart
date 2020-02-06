import 'package:process_run/shell_run.dart';

Future main() async {
  await run('flutter run -t lib/main_demo_ffi.dart -d Linux');
}
