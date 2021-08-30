import 'dart:async';

@Deprecated('Not defined')
abstract class CursorRow {}

@Deprecated('Not defined')
abstract class Cursor {
  // int _totalCount;
  // int _pageCount;
  bool isSyncAvailable(int index);

  bool get count;

  FutureOr<CursorRow> moveTo(int index);
}
