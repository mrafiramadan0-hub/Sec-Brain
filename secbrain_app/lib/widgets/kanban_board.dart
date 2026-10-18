import 'package:flutter/material.dart';

import '../main.dart';
import 'overdue_badge.dart';

enum TaskStatus {
  todo('To Do', Color(0xFF546E7A), Color(0xFFECEFF1)),
  inProgress('In Progress', Color(0xFFD97706), amberLight),
  done('Done', green, greenLight);

  const TaskStatus(this.label, this.primaryColor, this.bgColor);
  final String label;
  final Color primaryColor;
  final Color bgColor;
}

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({super.key, required this.store});
  final BrainStore store;

  TaskStatus _getTaskStatus(Task task) {
    if (task.done) return TaskStatus.done;
    if (task.inProgress) return TaskStatus.inProgress;
    return TaskStatus.todo;
  }

  void _updateTaskStatus(Task task, TaskStatus newStatus) {
    switch (newStatus) {
      case TaskStatus.todo:
        task.done = false;
        task.inProgress = false;
        break;
      case TaskStatus.inProgress:
        task.done = false;
        task.inProgress = true;
        break;
      case TaskStatus.done:
        task.done = true;
        task.inProgress = false;
        break;
    }
    store.save();
  }

  @override
  Widget build(BuildContext context) {
    final todoTasks = store.tasks
        .where((t) => !t.done && !t.inProgress)
        .toList();
    final inProgressTasks = store.tasks
        .where((t) => !t.done && t.inProgress)
        .toList();
    final doneTasks = store.tasks.where((t) => t.done).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 768;

        final columns = [
          _buildColumn(context, TaskStatus.todo, todoTasks),
          _buildColumn(context, TaskStatus.inProgress, inProgressTasks),
          _buildColumn(context, TaskStatus.done, doneTasks),
        ];

        if (!isWide) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: columns
                  .map(
                    (col) => SizedBox(
                      width: 280,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: col,
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns
              .map(
                (col) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: col,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildColumn(
    BuildContext context,
    TaskStatus status,
    List<Task> tasks,
  ) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) =>
          _getTaskStatus(details.data) != status,
      onAcceptWithDetails: (details) {
        _updateTaskStatus(details.data, status);
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isHighlighted
                ? (isDark
                      ? status.primaryColor.withValues(alpha: 0.25)
                      : status.bgColor.withValues(alpha: 0.8))
                : (isDark ? const Color(0xFF19201C) : const Color(0xFFF2F4F2)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted ? status.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Column Header
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: status.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: status.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF26322C) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: muted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (status == TaskStatus.todo)
                    IconButton(
                      icon: const Icon(Icons.add, size: 18, color: muted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => showTaskDialog(context, store),
                      tooltip: 'Tambah Task Baru',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Tarik task ke sini',
                      style: TextStyle(
                        color: muted.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
              else
                ...tasks.map(
                  (task) => _buildDraggableCard(context, task, status),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableCard(
    BuildContext context,
    Task task,
    TaskStatus currentStatus,
  ) {
    final now = DateTime.now();
    final isOverdue = !task.done && task.due.isBefore(now);

    final cardContent = Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isOverdue
              ? coral.withValues(alpha: 0.5)
              : muted.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: task.done
                          ? muted
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : ink),
                      decoration: task.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 16, color: muted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'todo') {
                      _updateTaskStatus(task, TaskStatus.todo);
                    } else if (val == 'inProgress') {
                      _updateTaskStatus(task, TaskStatus.inProgress);
                    } else if (val == 'done') {
                      _updateTaskStatus(task, TaskStatus.done);
                    } else if (val == 'delete') {
                      store.deleteTask(task);
                    }
                  },
                  itemBuilder: (context) => [
                    if (currentStatus != TaskStatus.todo)
                      const PopupMenuItem(
                        value: 'todo',
                        child: Text('Pindah ke To Do'),
                      ),
                    if (currentStatus != TaskStatus.inProgress)
                      const PopupMenuItem(
                        value: 'inProgress',
                        child: Text('Pindah ke In Progress'),
                      ),
                    if (currentStatus != TaskStatus.done)
                      const PopupMenuItem(
                        value: 'done',
                        child: Text('Tandai Selesai'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus Task', style: TextStyle(color: coral)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TaskCategoryChip(category: task.category),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: task.priority == 'High' ? coralLight : amberLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: task.priority == 'High'
                          ? coral
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 11,
                  color: isOverdue ? coral : muted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${task.due.day}/${task.due.month} ${task.due.hour.toString().padLeft(2, '0')}:${task.due.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOverdue ? coral : muted,
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(width: 4),
                  const Text(
                    '• Overdue',
                    style: TextStyle(
                      color: coral,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    return LongPressDraggable<Task>(
      data: task,
      feedback: SizedBox(
        width: 260,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: cardContent,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cardContent),
      child: cardContent,
    );
  }
}
