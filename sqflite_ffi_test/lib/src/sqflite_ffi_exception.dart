import 'package:meta/meta.dart';
import 'package:sqflite/src/exception.dart';

import 'import.dart';

class SqfliteFfiException extends SqfliteDatabaseException {
  final String code;
  Map<String, dynamic> details;

  SqfliteFfiException(
      {@required this.code, @required String message, this.details})
      : super(message, details);

  @override
  String toString() {
    var map = <String, dynamic>{};
    if (details != null) {
      map['details'] = details;
    }
    return 'SqfliteFfiException($code, $message} ${super.toString()} $map';
  }
}
