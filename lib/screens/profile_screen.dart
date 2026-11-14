import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/edit_name_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _avatars = <String, IconData>{
    'persona': Icons.person_rounded,
    'rostro': Icons.face_rounded,
    'estrella': Icons.star_rounded,
    'mascota': Icons.pets_rounded,
    'cohete': Icons.rocket_launch_rounded,
    'corazon': Icons.favorite_rounded,
  };
  static const _avatarPrefix = 'gestor-avatar:';
  final _auth = AuthService();
  bool _saving = false;

  String? _selectedAvatar(User? user) {
    final photoUrl = user?.photoURL;
    if (photoUrl == null || !photoUrl.startsWith(_avatarPrefix)) return null;
    final avatarId = photoUrl.substring(_avatarPrefix.length);
    return _avatars.containsKey(avatarId) ? avatarId : null;
  }

  Future<void> _editName(User? user) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => EditNameDialog(initialName: user?.displayName ?? ''),
    );
    if (name == null || name.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _auth.updateDisplayName(name);
      if (mounted) {
        setState(() {});
        _showMessage('Nombre actualizado.');
      }
    } catch (error) {
      if (mounted) _showMessage('No se pudo actualizar el nombre: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseAvatar() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elige tu avatar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _avatars.entries.map((entry) {
                  return IconButton.filledTonal(
                    tooltip: 'Avatar ${entry.key}',
                    iconSize: 30,
                    onPressed: () => Navigator.pop(context, entry.key),
                    icon: Icon(entry.value),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;

    setState(() => _saving = true);
    try {
      await _auth.updateAvatar(selected);
      if (mounted) {
        setState(() {});
        _showMessage('Avatar actualizado.');
      }
    } catch (error) {
      if (mounted) _showMessage('No se pudo actualizar el avatar: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _auth.logout();
    } catch (error) {
      if (mounted) _showMessage('No se pudo cerrar sesión: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = context.watch<ThemeProvider>();
    final avatarId = _selectedAvatar(user);
    final displayName = user?.displayName?.trim();
    final name = displayName == null || displayName.isEmpty
        ? (user?.email?.split('@').first ?? 'Usuario')
        : displayName;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                wide ? 24 : 16,
                24,
                wide ? 24 : 16,
                32,
              ),
              children: [
                _profileCard(user, avatarId, name, wide),
                const SizedBox(height: 28),
                Text(
                  'Preferencias',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Modo oscuro'),
                        subtitle: const Text('Ajusta el tema de la aplicación'),
                        value: theme.isDark,
                        onChanged: (_) => theme.toggleDark(),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Color principal',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Personaliza los detalles de color.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                _colorOption(theme, Colors.indigo, 'Índigo'),
                                _colorOption(
                                  theme,
                                  Colors.teal,
                                  'Verde azulado',
                                ),
                                _colorOption(theme, Colors.orange, 'Naranja'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _profileCard(User? user, String? avatarId, String name, bool wide) {
    final avatar = Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            _avatars[avatarId] ?? Icons.person_rounded,
            size: 38,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        IconButton.filled(
          tooltip: 'Cambiar avatar',
          onPressed: _saving ? null : _chooseAvatar,
          icon: const Icon(Icons.edit_rounded, size: 17),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
    final identity = Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          user?.email ?? 'Sin correo disponible',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: wide ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _saving ? null : () => _editName(user),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Editar nombre'),
        ),
      ],
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: wide
            ? Row(
                children: [
                  avatar,
                  const SizedBox(width: 20),
                  Expanded(child: identity),
                  Icon(
                    Icons.manage_accounts_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              )
            : Column(children: [avatar, const SizedBox(height: 14), identity]),
      ),
    );
  }

  Widget _colorOption(ThemeProvider theme, Color color, String label) {
    final selected = theme.seed == color;
    return ChoiceChip(
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      label: Text(label),
      selected: selected,
      onSelected: (_) => theme.setColor(color),
    );
  }
}
