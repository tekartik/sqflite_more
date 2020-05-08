/// Add sqflite dependencies in a brut force way
String pubspecStringAddSqflite(String content) {
  return content.replaceAllMapped(RegExp(r'^dependencies:$', multiLine: true),
      (match) => 'dependencies:\n  sqflite:');
}
