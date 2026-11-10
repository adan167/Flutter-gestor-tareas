# Gestor de Tareas

Aplicación Flutter para organizar tareas personales, de trabajo, estudio y del
hogar. Utiliza Firebase Authentication para las cuentas, Cloud Firestore para
la sincronización en tiempo real y notificaciones locales para recordatorios.
La interfaz y el calendario están en español; la lista permite filtrar por
categoría y por estado, editar o eliminar tareas.

## Requisitos

- Flutter y Dart compatibles con las versiones declaradas en `pubspec.yaml`.
- Proyecto de Firebase con Authentication (correo y contraseña) y Cloud
  Firestore habilitados.
- Android Studio/Xcode para ejecutar en Android/iOS, respectivamente.

## Configuración de Firebase

El proyecto contiene `lib/firebase_options.dart`. Para generar o actualizar la
configuración de las plataformas desde tu cuenta de Firebase, ejecuta:

```shell
flutterfire configure
```

Publica estas reglas en Firestore para que cada cuenta solo pueda acceder a sus
propias tareas:

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Ejecución

```shell
flutter pub get
flutter run
```

Las notificaciones programadas usan la zona horaria `America/Lima`. Android
solicita permiso para mostrar notificaciones; iOS solicita permisos de alerta,
sonido y distintivo al iniciar la app. Para ejecutar en iOS, instala también los
pods desde `ios` en macOS con `pod install`.
En la versión web, las tareas se guardan normalmente, pero los recordatorios
locales no están disponibles; la aplicación informa de esta limitación al
guardar una tarea con fecha de aviso.

## Pruebas y documentación

- Casos manuales: [PRUEBAS.md](./PRUEBAS.md).
- Diagramas Mermaid: [docs/arquitectura.md](./docs/arquitectura.md),
  [docs/esquema-firestore.md](./docs/esquema-firestore.md) y
  [docs/flujo-usuario.md](./docs/flujo-usuario.md).
