import 'package:flutter/material.dart';

/// Integer text field that pushes parsed values immediately but does not
/// overwrite what the user is typing while it has focus.
class IntField extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int? min;
  final int? max;

  const IntField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
  });

  @override
  State<IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<IntField> {
  late final TextEditingController _text =
      TextEditingController(text: widget.value.toString());
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(IntField old) {
    super.didUpdateWidget(old);
    // Sync when the model changed elsewhere (undo, drag) but not while the
    // typed text already parses to the current value.
    if (old.value != widget.value &&
        int.tryParse(_text.text.trim()) != widget.value) {
      _text.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) return;
    var v = parsed;
    if (widget.min != null && v < widget.min!) v = widget.min!;
    if (widget.max != null && v > widget.max!) v = widget.max!;
    if (v != widget.value) widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      focusNode: _focus,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      decoration: InputDecoration(labelText: widget.label, isDense: true),
      onChanged: _submit,
    );
  }
}

/// Multi-line string field with the same focus-aware sync as [IntField].
class StringField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const StringField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<StringField> createState() => _StringFieldState();
}

class _StringFieldState extends State<StringField> {
  late final TextEditingController _text =
      TextEditingController(text: widget.value);
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(StringField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _text.text != widget.value) {
      _text.text = widget.value;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      focusNode: _focus,
      maxLines: widget.maxLines,
      decoration: InputDecoration(labelText: widget.label, isDense: true),
      onChanged: widget.onChanged,
    );
  }
}

/// Dropdown over an enum's values, labelled by `name`.
class EnumDropdown<T extends Enum> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> values;
  final ValueChanged<T?> onChanged;
  final bool nullable;

  const EnumDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.nullable = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        if (nullable) const DropdownMenuItem(value: null, child: Text('none')),
        for (final v in values) DropdownMenuItem(value: v, child: Text(v.name)),
      ],
      onChanged: onChanged,
    );
  }
}

class BoolSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const BoolSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}
