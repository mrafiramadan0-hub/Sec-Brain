import 'package:flutter/material.dart';

import '../main.dart';

class CrossLinkChips extends StatelessWidget {
  const CrossLinkChips({
    super.key,
    required this.linkedTaskTitles,
    this.onTaskTap,
    this.isEditable = false,
    this.onRemove,
  });

  final List<String> linkedTaskTitles;
  final ValueChanged<String>? onTaskTap;
  final bool isEditable;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (linkedTaskTitles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.link_rounded, size: 14, color: muted),
            SizedBox(width: 4),
            Text(
              'LINKED TASKS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: muted,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: linkedTaskTitles.map((taskTitle) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return InputChip(
              avatar: const Icon(
                Icons.check_circle_outline,
                size: 14,
                color: green,
              ),
              label: Text(
                taskTitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF86EFAC) : ink,
                ),
              ),
              backgroundColor: isDark ? const Color(0xFF1F352B) : greenLight,
              side: BorderSide.none,
              onPressed: onTaskTap != null ? () => onTaskTap!(taskTitle) : null,
              onDeleted: isEditable && onRemove != null
                  ? () => onRemove!(taskTitle)
                  : null,
              deleteIconColor: coral,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class TaskLinkSelectorDialog extends StatefulWidget {
  const TaskLinkSelectorDialog({
    super.key,
    required this.availableTasks,
    required this.initiallySelected,
  });

  final List<Task> availableTasks;
  final List<String> initiallySelected;

  @override
  State<TaskLinkSelectorDialog> createState() => _TaskLinkSelectorDialogState();
}

class _TaskLinkSelectorDialogState extends State<TaskLinkSelectorDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.link_rounded, color: green),
          SizedBox(width: 8),
          Text('Tautkan ke Task'),
        ],
      ),
      content: SizedBox(
        width: 380,
        height: 300,
        child: widget.availableTasks.isEmpty
            ? const Center(child: Text('Tidak ada task aktif untuk ditautkan'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableTasks.length,
                itemBuilder: (context, index) {
                  final task = widget.availableTasks[index];
                  final isChecked = _selected.contains(task.title);
                  return CheckboxListTile(
                    value: isChecked,
                    title: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${task.category} • ${task.priority}',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    activeColor: green,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selected.add(task.title);
                        } else {
                          _selected.remove(task.title);
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected.toList()),
          child: const Text('Simpan Tautan'),
        ),
      ],
    );
  }
}
