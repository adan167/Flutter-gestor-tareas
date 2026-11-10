import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Pantalla de inicio de sesión y registro (se alternan con un botón).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Para validar los campos
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();
  bool _isLogin = true; // true = iniciar sesión, false = registrarse
  bool _loading = false;

  /// Valida el formulario y llama a Firebase Auth.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await _auth.login(_email.text.trim(), _pass.text);
      } else {
        await _auth.register(_email.text.trim(), _pass.text);
      }
      // No navegamos manualmente: el StreamBuilder de main.dart lo hace.
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = error.message ?? 'Error de autenticación.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar la operación: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestor de Tareas',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return email.contains('@') && email.contains('.')
                          ? null
                          : 'Correo inválido';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pass,
                    obscureText: true,
                    autofillHints: [
                      _isLogin
                          ? AutofillHints.password
                          : AutofillHints.newPassword,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.length < 6)
                        ? 'Mínimo 6 caracteres'
                        : null,
                    onFieldSubmitted: (_) => _loading ? null : _submit(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin ? 'Iniciar sesión' : 'Crear cuenta'),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
