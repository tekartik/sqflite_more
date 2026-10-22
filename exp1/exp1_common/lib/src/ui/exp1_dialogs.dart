import 'package:material_ui/material_ui.dart';
import 'package:sqflite_exp1_common/src/ui/exp1_id.dart';

/// Asks for a name, null if cancelled or empty.
Future<String?> showExp1NameDialog(
  BuildContext context, {
  required String title,
  required String label,
}) async {
  var name = await showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(title: title, label: label),
  );
  return (name?.isEmpty ?? true) ? null : name;
}

class _NameDialog extends StatefulWidget {
  final String title;
  final String label;

  const _NameDialog({required this.title, required this.label});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Exp1Id(
        Exp1Ids.nameField,
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(labelText: widget.label),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        Exp1Id(
          Exp1Ids.dialogCancel,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ),
        Exp1Id(
          Exp1Ids.dialogOk,
          child: TextButton(onPressed: _submit, child: const Text('OK')),
        ),
      ],
    );
  }
}

/// Asks for a confirmation.
Future<bool> showExp1ConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  var confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        Exp1Id(
          Exp1Ids.dialogCancel,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
        ),
        Exp1Id(
          Exp1Ids.dialogOk,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
