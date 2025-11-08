import 'package:flutter/material.dart';
import 'package:tempo_pilot/features/calendar/models/calendar_source.dart';

/// Row widget for displaying a calendar with include toggle.
class CalendarPickerRow extends StatelessWidget {
  const CalendarPickerRow({
    super.key,
    required this.source,
    required this.onToggle,
  });

  final CalendarSource source;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        Icons.calendar_today,
        color: source.included
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(source.name, overflow: TextOverflow.ellipsis),
      subtitle: _buildSubtitle(subtitleStyle),
      trailing: Semantics(
        container: true,
        label: 'Include ${source.name}',
        value: source.included ? 'Included' : 'Excluded',
        toggled: source.included,
        child: Switch(
          value: source.included,
          onChanged: onToggle,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget? _buildSubtitle(TextStyle? subtitleStyle) {
    final rows = <Widget>[];

    if (source.accountName != null && source.accountName!.isNotEmpty) {
      rows.add(Text(source.accountName!, style: subtitleStyle));
    }

    if (source.isPrimary ||
        (source.accountType != null && source.accountType!.isNotEmpty)) {
      rows.add(
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (source.isPrimary)
              Chip(
                label: const Text('Primary'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            if (source.accountType != null && source.accountType!.isNotEmpty)
              Chip(
                label: Text(source.accountType!),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
      );
    }

    if (rows.isEmpty) {
      return null;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}
