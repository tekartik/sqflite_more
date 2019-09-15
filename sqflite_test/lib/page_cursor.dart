import 'dart:async';

abstract class CursorRow {}

abstract class Cursor {
  // int _totalCount;
  // int _pageCount;
  bool isSyncAvailable(int index);
  bool get count;
  FutureOr<CursorRow> moveTo(int index);
}
