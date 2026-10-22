/// Ids of the widgets driven by the scenario tool.
///
/// Each id is both a `ValueKey` (`find.byValueKey(id)` in flutter_driver)
/// and a `Semantics.identifier` (Android `resource-id` for uiautomator, web
/// `flt-semantics-identifier`, iOS `accessibilityIdentifier`).
abstract final class Exp1Ids {
  /// Floating button adding a list.
  static const addList = 'add_list';

  /// Floating button adding a task.
  static const addTask = 'add_task';

  /// Text field of the name dialog.
  static const nameField = 'name_field';

  /// OK button of the dialogs.
  static const dialogOk = 'dialog_ok';

  /// Cancel button of the dialogs.
  static const dialogCancel = 'dialog_cancel';

  /// Menu button of the lists page.
  static const menu = 'menu';

  /// Menu item resetting the demo database.
  static const menuReset = 'menu_reset';

  /// Menu item holding a write transaction (hot restart test).
  static const menuHoldTransaction = 'menu_hold_transaction';

  /// Banner shown once the transaction is held.
  static const heldBanner = 'held_banner';

  /// Back button of the tasks page (flutter_driver `find.pageBack()` and
  /// `find.byTooltip()` only know the flutter/material widgets, not the
  /// material_ui ones).
  static const back = 'back';

  /// Delete button of the tasks page.
  static const deleteList = 'delete_list';

  /// List tile of a todo list.
  static String list(int id) => 'list_$id';

  /// Checkbox of a task.
  static String taskDone(int id) => 'task_${id}_done';

  /// Delete button of a task.
  static String taskDelete(int id) => 'task_${id}_delete';
}
