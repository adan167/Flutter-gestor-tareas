import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';

/// Formulario para crear o editar una tarea.
/// Si recibe [task], está en modo edición; si no, es una tarea nueva.
class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TaskService();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  String _category = 'Personal';
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Si se edita, se cargan los datos existentes en el formulario.
    _title = TextEditingController(text: widget.task?.title ?? '');
    _desc = TextEditingController(text: widget.task?.description ?? '');
    _category = widget.task?.category ?? 'Personal';
    _dueDate = widget.task?.dueDate;
  }

  /// Selector de fecha y luego de hora para el recordatorio.
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initialDate = _dueDate != null && _dueDate!.isAfter(now)
        ? _dueDate!
        : now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3, now.month, now.day),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(
      () => _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  /// Guarda en Firestore (crea o actualiza) y vuelve a la lista.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final task = TaskModel(
      id: widget.task?.id ?? '',
      title: _title.text.trim(),
      description: _desc.text.trim(),
      category: _category,
      dueDate: _dueDate,
      isDone: widget.task?.isDone ?? false,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
    );
    try {
      if (widget.task == null) {
        await _service.addTask(task);
      } else {
        await _service.updateTask(task);
      }
      if (mounted) {
        Navigator.pop(
          context,
          _dueDate != null &&
              !NotificationService.instance.supportsScheduledNotifications,
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la tarea: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nueva tarea' : 'Editar tarea'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Escribe un título'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              items: ['Personal', 'Trabajo', 'Estudio', 'Hogar']
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.alarm),
              label: Text(
                _dueDate == null
                    ? 'Agregar recordatorio'
                    : DateFormat('dd/MM/yyyy HH:mm').format(_dueDate!),
              ),
            ),
            if (_dueDate != null &&
                !NotificationService.instance.supportsScheduledNotifications)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Los recordatorios no están disponibles en esta plataforma. '
                  'La tarea se guardará; el aviso requiere Android o iOS.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_dueDate != null)
              TextButton(
                onPressed: () => setState(() => _dueDate = null),
                child: const Text('Quitar recordatorio'),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
