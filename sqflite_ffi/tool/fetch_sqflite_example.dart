import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';

Future sparseCheckout({String dir, String url, List<String> remoteDirs}) async {
  await Directory(dir).create(recursive: true);
  await Directory(dir).delete(recursive: true);
  await Directory(dir).create(recursive: true);

  //exit(0);
  var tmpShell = Shell().pushd(dir);
  await tmpShell.run('''
  git --version
  ls .
  
 
git init
git config core.sparseCheckout true
git remote add origin $url

  ''');

  if (remoteDirs?.isNotEmpty ?? false) {
    await File(join(dir, '.git/info/sparse-checkout'))
        .writeAsString(remoteDirs.join('\n'));
  }

  await tmpShell.run('''
  git pull --depth=1 origin master
  ''');
}

Future main() async {
  var dir = 'tmp/sqflite_example';
  await sparseCheckout(
      dir: 'tmp/sqflite_example',
      url: 'git@github.com:tekartik/sqflite.git',
      remoteDirs: ['example']);
  exit(0);
  await Directory(dir).create(recursive: true);
  await Directory(dir).delete(recursive: true);
  await Directory(dir).create(recursive: true);

  var text = '''^
  ''';
  print('[$text] ${text.codeUnits}');
  //exit(0);
  var tmpShell = Shell().pushd(dir);
  await tmpShell.run('''
  git --version
  ls .
  
 
git init
git remote add -f ^
  origin git@github.com:tekartik/sqflite.git
git config core.sparseCheckout true
  
  ''');

  await File(join(dir, '.git/info/sparse-checkout')).writeAsString('''
example
''');

  await tmpShell.run('''
  git pull origin master
  ''');
}
