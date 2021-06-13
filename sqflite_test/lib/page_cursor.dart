import 'dart:async';

@deprecated
abstract class CursorRow {}

@deprecated
abstract class Cursor {
  // int _totalCount;
  // int _pageCount;
  bool isSyncAvailable(int index);

  bool get count;

  FutureOr<CursorRow> moveTo(int index);
}
