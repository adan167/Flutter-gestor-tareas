import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_model.dart';
import 'notification_service.dart';

/// CRUD de tareas sobre Firestore: users/{uid}/tasks/{taskId}
class TaskService {
  /// Referencia a la subcolección de tareas del usuario logueado.
  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Debes iniciar sesión para administrar tus tareas.');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');
  }

  /// STREAM EN TIEMPO REAL: cada cambio en la nube llega a todos los
  /// dispositivos conectados automáticamente. Aquí está la sincronización.
  Stream<List<TaskModel>> watchTasks() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TaskModel.fromDoc).toList());
  }

  /// CREATE: agrega una tarea y programa su recordatorio.
  Future<void> addTask(TaskModel task) async {
    final ref = await _col.add(task.toMap());
    if (task.dueDate != null && !task.isDone) {
      await NotificationService.instance.schedule(
        ref.id,
        task.title,
        task.dueDate!,
      );
    }
  }

  /// UPDATE: edita una tarea y reprograma su recordatorio.
  Future<void> updateTask(TaskModel task) async {
    await _col.doc(task.id).update(task.toMap());
    await NotificationService.instance.cancel(task.id);
    if (task.dueDate != null && !task.isDone) {
      await NotificationService.instance.schedule(
        task.id,
        task.title,
        task.dueDate!,
      );
    }
  }

  /// Seguimiento: marca como completada o pendiente.
  Future<void> toggleDone(TaskModel task) async {
    await _col.doc(task.id).update({'isDone': !task.isDone});
    // Si se completa, ya no hace falta el recordatorio.
    if (!task.isDone) {
      await NotificationService.instance.cancel(task.id);
    } else if (task.dueDate != null) {
      await NotificationService.instance.schedule(
        task.id,
        task.title,
        task.dueDate!,
      );
    }
  }

  /// DELETE: elimina la tarea y cancela su recordatorio.
  Future<void> deleteTask(String id) async {
    await _col.doc(id).delete();
    await NotificationService.instance.cancel(id);
  }
}
