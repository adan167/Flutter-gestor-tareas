import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';
import 'profile_screen.dart';
import 'task_form_screen.dart';

/// Pantalla principal: lista de tareas en tiempo real con filtros.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = TaskService();
  late final Stream<List<TaskModel>> _tasksStream;
  int _selectedIndex = 0;
  String _filter = 'Todas'; // Categoría seleccionada en los chips
  String _statusFilter = 'Todas';
  static const categories = [
    'Todas',
    'Personal',
    'Trabajo',
    'Estudio',
    'Hogar',
  ];
  static const statuses = ['Pendientes', 'Completadas'];

  @override
  void initState() {
    super.initState();
    _tasksStream = _service.watchTasks();
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo completar la operación: $error')),
    );
  }

  Future<void> _toggleDone(TaskModel task) async {
    try {
      await _service.toggleDone(task);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      await _service.deleteTask(id);
    } catch (error) {
      _showError(error);
    }
  }

  Future<bool> _confirmDelete(TaskModel task) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar tarea'),
            content: Text('¿Quieres eliminar "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteTaskWithConfirmation(TaskModel task) async {
    if (await _confirmDelete(task)) {
      await _deleteTask(task.id);
    }
  }

  Future<void> _openTaskForm({TaskModel? task}) async {
    final reminderUnavailable = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => TaskFormScreen(task: task)),
    );
    if (mounted && reminderUnavailable == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La tarea se guardó. Los recordatorios requieren Android o iOS.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          width: 52,
          height: 44,
          fit: BoxFit.contain,
          semanticLabel: 'Gestor de tareas',
        ),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          final tasks = snapshot.data;
          return IndexedStack(
            index: _selectedIndex,
            children: [
              tasks == null ? _taskLoadState(snapshot) : _dashboard(tasks),
              tasks == null ? _taskLoadState(snapshot) : _taskList(tasks),
              const ProfileScreen(),
            ],
          );
        },
      ),
      floatingActionButton: _selectedIndex != 1
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openTaskForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarea'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _taskLoadState(AsyncSnapshot<List<TaskModel>> snapshot) {
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error al cargar las tareas: ${snapshot.error}'),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _dashboard(List<TaskModel> tasks) {
    final pending = tasks.where((task) => !task.isDone).length;
    final completed = tasks.where((task) => task.isDone).length;
    final total = tasks.length;
    final completion = total == 0 ? 0.0 : completed / total;
    final overdue = tasks
        .where(
          (task) =>
              !task.isDone &&
              task.dueDate != null &&
              task.dueDate!.isBefore(DateTime.now()),
        )
        .length;
    final upcoming =
        tasks
            .where(
              (task) =>
                  !task.isDone &&
                  task.dueDate != null &&
                  !task.dueDate!.isBefore(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final userName = FirebaseAuth.instance.currentUser?.displayName;
    final greeting = userName == null || userName.trim().isEmpty
        ? 'Bienvenido'
        : 'Hola, ${userName.trim()}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final content = ListView(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 24, wide ? 28 : 16, 32),
          children: [
            _dashboardHeader(greeting, wide),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Resumen de tareas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _summaryCards(
              pending: pending,
              completed: completed,
              overdue: overdue,
              wide: wide,
            ),
            const SizedBox(height: 24),
            _progressCard(completed, total, completion),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Próximas fechas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  child: const Text('Ver tareas'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              _emptyUpcomingCard()
            else
              ...upcoming.take(3).map((task) => _upcomingTaskCard(task)),
          ],
        );
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: content,
          ),
        );
      },
    );
  }

  Widget _dashboardHeader(String greeting, bool wide) {
    final colors = Theme.of(context).colorScheme;
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TU ESPACIO DE TRABAJO',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.onPrimary.withValues(alpha: 0.78),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: colors.onPrimary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Planifica con claridad. Avanza a tu ritmo.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: colors.onPrimary.withValues(alpha: 0.86)),
        ),
      ],
    );
    final createButton = FilledButton.tonalIcon(
      onPressed: _openTaskForm,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Nueva tarea'),
      style: FilledButton.styleFrom(
        foregroundColor: colors.primary,
        backgroundColor: colors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
    return Container(
      padding: EdgeInsets.all(wide ? 28 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: wide
          ? Row(
              children: [
                Expanded(child: intro),
                const SizedBox(width: 20),
                createButton,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [intro, const SizedBox(height: 20), createButton],
            ),
    );
  }

  Widget _summaryCards({
    required int pending,
    required int completed,
    required int overdue,
    required bool wide,
  }) {
    final values = [
      ('Pendientes', pending, Icons.pending_actions_rounded),
      ('Completadas', completed, Icons.task_alt_rounded),
      ('Vencidas', overdue, Icons.event_busy_outlined),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: values
          .map(
            (item) => SizedBox(
              width: wide
                  ? (MediaQuery.sizeOf(context).width.clamp(0, 1080) - 80) / 3
                  : double.infinity,
              child: _summaryCard(item.$1, item.$2, item.$3),
            ),
          )
          .toList(),
    );
  }

  Widget _summaryCard(String title, int count, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count', style: Theme.of(context).textTheme.titleLarge),
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCard(int completed, int total, double progress) {
    final percentage = (progress * 100).round();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Progreso general',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$completed de $total tareas completadas',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyUpcomingCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.event_available_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'No tienes fechas próximas. Tus tareas con fecha aparecerán aquí.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcomingTaskCard(TaskModel task) {
    final dueDate = task.dueDate!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event_note_rounded)),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${task.category} · ${DateFormat('dd/MM/yyyy HH:mm').format(dueDate)}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _openTaskForm(task: task),
      ),
    );
  }

  Widget _taskList(List<TaskModel> allTasks) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              ...categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _filter == category,
                    onSelected: (_) => setState(() {
                      _filter = category;
                      _statusFilter = 'Todas';
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ...statuses.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: _statusFilter == status,
                    onSelected: (_) => setState(() {
                      _filter = 'Todas';
                      _statusFilter = status;
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _filteredTaskList(allTasks)),
      ],
    );
  }

  Widget _filteredTaskList(List<TaskModel> allTasks) {
    final tasks = allTasks
        .where(
          (task) =>
              (_filter == 'Todas' || task.category == _filter) &&
              (_statusFilter == 'Todas' ||
                  (_statusFilter == 'Completadas' && task.isDone) ||
                  (_statusFilter == 'Pendientes' && !task.isDone)),
        )
        .toList();
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          _statusFilter == 'Completadas'
              ? 'No hay tareas completadas'
              : _statusFilter == 'Pendientes'
              ? 'No hay tareas pendientes'
              : 'No hay tareas aún',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88, top: 4),
      itemCount: tasks.length,
      itemBuilder: (_, index) => _taskTile(tasks[index]),
    );
  }

  /// Tarjeta de una tarea. Deslizar a la izquierda elimina.
  Widget _taskTile(TaskModel task) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(task),
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteTask(task.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          leading: Checkbox(
            value: task.isDone,
            onChanged: (_) => _toggleDone(task), // Seguimiento
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${task.category}'
            ' • ${task.isDone ? 'Completada' : 'Pendiente'}'
            '${task.dueDate != null ? ' • ${DateFormat('dd/MM/yyyy HH:mm').format(task.dueDate!)}' : ''}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar tarea',
                onPressed: () => _openTaskForm(task: task),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Eliminar tarea',
                onPressed: () => _deleteTaskWithConfirmation(task),
              ),
            ],
          ),
          onTap: () => _openTaskForm(task: task),
        ),
      ),
    );
  }
}
