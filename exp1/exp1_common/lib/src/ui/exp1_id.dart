import 'package:material_ui/material_ui.dart';
import 'package:sqflite_exp1_common/src/exp1_ids.dart';

export 'package:sqflite_exp1_common/src/exp1_ids.dart';

/// Identifies [child] with [id] for the scenario tool, see [Exp1Ids].
class Exp1Id extends StatelessWidget {
  /// Id.
  final String id;

  /// Identified widget.
  final Widget child;

  /// Identifies [child] with [id].
  Exp1Id(this.id, {required this.child}) : super(key: ValueKey(id));

  @override
  Widget build(BuildContext context) => Semantics(identifier: id, child: child);
}
