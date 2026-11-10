import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
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

  Future<void> _logout() async {
    try {
      await AuthService().logout();
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tareas'),
        actions: [
          // Menú de personalización de la interfaz
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Personalizar apariencia',
            onSelected: (value) {
              switch (value) {
                case 'dark':
                  theme.toggleDark();
                case 'indigo':
                  theme.setColor(Colors.indigo);
                case 'teal':
                  theme.setColor(Colors.teal);
                case 'orange':
                  theme.setColor(Colors.orange);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'dark', child: Text('Modo claro/oscuro')),
              PopupMenuItem(value: 'indigo', child: Text('Color índigo')),
              PopupMenuItem(value: 'teal', child: Text('Color verde azulado')),
              PopupMenuItem(value: 'orange', child: Text('Color naranja')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros por categoría y estado
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
          Expanded(
            // Lista en tiempo real: se actualiza sola ante cualquier cambio
            child: StreamBuilder<List<TaskModel>>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error al cargar las tareas: ${snapshot.error}',
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!
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
                  itemCount: tasks.length,
                  itemBuilder: (_, index) => _taskTile(tasks[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
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
