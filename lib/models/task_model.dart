import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa una tarea. Se convierte desde/hacia Firestore.
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime? dueDate; // Fecha del recordatorio (opcional)
  final bool isDone; // Seguimiento: pendiente o completada
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    this.dueDate,
    this.isDone = false,
    required this.createdAt,
  });

  /// Convierte un documento de Firestore en un objeto TaskModel.
  factory TaskModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('El documento ${doc.id} no contiene datos.');
    }

    final dueDate = data['dueDate'];
    final createdAt = data['createdAt'];
    return TaskModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Personal',
      dueDate: dueDate is Timestamp ? dueDate.toDate() : null,
      isDone: data['isDone'] as bool? ?? false,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  /// Convierte el objeto en un Map para guardarlo en Firestore.
  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'category': category,
    'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
    'isDone': isDone,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
