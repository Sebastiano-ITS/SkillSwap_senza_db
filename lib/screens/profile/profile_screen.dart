// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local_data.dart';
import '../../flutter_bloc/profile_bloc/profile_cubit.dart';
import '../../flutter_bloc/profile_bloc/profile_state.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/brand_palette.dart';

import '../../widgets/editable_skill_list.dart';
import 'profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controller input
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  double _radiusKm = 3;
  String? _birthIso;
  bool _isEditing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(UserProfile user, ProfileCubit cubit) async {
    final picker = ImagePicker();
    final XFile? file =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${appDir.path}/skillswap/avatars');
    if (!await dir.exists()) await dir.create(recursive: true);

    final String ext = file.path.split('.').last;
    final String targetPath = '${dir.path}/${user.id}.$ext';
    await File(file.path).copy(targetPath);

    // aggiorna il cubit (se presente il metodo)
    try {
      cubit.updateImageUrl(targetPath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Immagine salvata localmente. Aggiungi updateImageUrl() nel Cubit per salvarla sul profilo.'),
          ),
        );
      }
    }
  }

  Future<void> _pickBirthDate(ProfileCubit cubit) async {
    final now = DateTime.now();
    final initial = _birthIso != null
        ? (DateTime.tryParse(_birthIso!) ?? DateTime(now.year - 18))
        : DateTime(now.year - 18);
    final first = DateTime(now.year - 100);
    final last = DateTime(now.year - 13);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Seleziona data di nascita',
    );
    if (picked != null) {
      _birthIso = picked.toIso8601String().substring(0, 10);
      try {
        cubit.updateBirthDateIso(_birthIso);
      } catch (_) {/* opzionale */}
      setState(() {});
    }
  }

  Future<void> _persistBasics() async {
    final updated = _user!.copyWith(
      name: _nameCtrl.text.trim().isEmpty ? _user!.name : _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? _user!.email : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      radiusKm: _radiusKm,
      birthDateIso: _birthIso,
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
    );
    await _saveUser(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profilo aggiornato')));
  }

  InputDecoration _decor(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withOpacity(0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: BrandPalette.purple, width: 1.4),
      ),
    );
  }

  void _logout() {
    context.read<AuthService>().signOut();
    LocalData().signOut();
    context.go('/login');
  }

  void _bindControllers(UserProfile u) {
    _nameCtrl.text = u.name;
    _emailCtrl.text = u.email;
    _phoneCtrl.text = u.phone ?? '';
    _cityCtrl.text = u.city ?? '';
    _bioCtrl.text = u.bio ?? '';
    _radiusKm = u.radiusKm ?? 3;
    _birthIso = u.birthDateIso;
  }

  void _toggleEdit(ProfileCubit cubit, ProfileState state) {
    if (!_isEditing) {
      setState(() => _isEditing = true);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annullare le modifiche?'),
        content: const Text('Le modifiche non salvate andranno perse.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continua a modificare'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isEditing = false);
              cubit.loadProfile(widget.userId); // scarta modifiche
            },
            child: const Text('Annulla modifiche'),
          ),
        ],
      ),
    );
  }

  void _save(ProfileCubit cubit) {
    cubit.saveProfile().then((_) => setState(() => _isEditing = false));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
      ProfileCubit(repository: LocalProfileRepository())..loadProfile(widget.userId),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (prev, curr) =>
        prev.feedbackMessage != curr.feedbackMessage ||
            prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          if (state.feedbackMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.feedbackMessage!)));
            context.read<ProfileCubit>().clearMessages();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            context.read<ProfileCubit>().clearMessages();
          }
        },
        builder: (context, state) {
          final cubit = context.read<ProfileCubit>();

          if (state.status == ProfileStatus.loading ||
              state.status == ProfileStatus.initial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.status == ProfileStatus.failure || state.profile == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Profilo')),
              body: Center(
                child: Text(state.errorMessage ?? 'Errore sconosciuto'),
              ),
            );
          }

          final u = state.profile!;
          _bindControllers(u);
          final theme = Theme.of(context);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Profilo'),
              centerTitle: false,
              backgroundColor: BrandPalette.purple,
              elevation: 0,
              actions: [

                const SizedBox(width: 4),
                if (!_isEditing)
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    label: const Text(
                      'Modifica',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  )
                else ...[
                  TextButton(
                    onPressed: () => _toggleEdit(cubit, state),
                    child: const Text(
                      'Annulla',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: state.hasUnsavedChanges ? () => _save(cubit) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withOpacity(0.5),
                    ),
                    child: Text(
                      'Salva',
                      style: TextStyle(
                        color: BrandPalette.purple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/background_color.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Container(color: Colors.white.withOpacity(0.25)),

                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header: avatar + nome/email
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        _Avatar(imagePath: u.imageUrl),
                                        if (_isEditing)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: InkWell(
                                              onTap: () => _pickAvatar(u, cubit),
                                              borderRadius: BorderRadius.circular(20),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: BrandPalette.purple,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            controller: _nameCtrl,
                                            readOnly: !_isEditing,
                                            decoration: _decor('Nome'),
                                            onChanged: (v) => cubit.updateName(v),
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: _emailCtrl,
                                            readOnly: !_isEditing,
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: _decor('Email'),
                                            onChanged: (v) => cubit.updateEmail(v),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Info base (i campi extra sono collegati ai metodi del Cubit se presenti)
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle(
                                      icon: Icons.badge_outlined,
                                      title: 'Informazioni di base',
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _phoneCtrl,
                                            readOnly: !_isEditing,
                                            keyboardType: TextInputType.phone,
                                            decoration: _decor('Cellulare'),
                                            onChanged: (v) {
                                              if (_isEditing) {
                                                try { cubit.updatePhone(v); } catch (_) {}
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _isEditing ? () => _pickBirthDate(cubit) : null,
                                            child: AbsorbPointer(
                                              absorbing: true,
                                              child: TextField(
                                                decoration: _decor('Data di nascita'),
                                                controller: TextEditingController(text: _birthIso ?? ''),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _cityCtrl,
                                            readOnly: !_isEditing,
                                            decoration: _decor('Città'),
                                            onChanged: (v) {
                                              if (_isEditing) {
                                                try { cubit.updateCity(v); } catch (_) {}
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Raggio (km): ${_radiusKm.round()}',
                                                style: theme.textTheme.labelLarge,
                                              ),
                                              Slider(
                                                value: _radiusKm,
                                                min: 1,
                                                max: 50,
                                                divisions: 49,
                                                activeColor: BrandPalette.magenta,
                                                thumbColor: BrandPalette.orange,
                                                label: '${_radiusKm.round()}',
                                                onChanged: _isEditing
                                                    ? (v) {
                                                  setState(() => _radiusKm = v);
                                                  try { cubit.updateRadiusKm(v); } catch (_) {}
                                                }
                                                    : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Bio
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle(icon: Icons.notes, title: 'Bio'),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _bioCtrl,
                                      readOnly: !_isEditing,
                                      maxLines: 5,
                                      minLines: 4,
                                      decoration: _decor('Scrivi una breve bio…'),
                                      onChanged: (v) {
                                        if (_isEditing) {
                                          try { cubit.updateBio(v); } catch (_) {}
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Skills: Can Teach
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle(icon: Icons.school, title: 'Puoi insegnare'),
                                    const SizedBox(height: 10),
                                    EditableSkillList(
                                      values: u.canTeach,
                                      isEditing: _isEditing,
                                      onAdd: () {
                                        if (!_isEditing) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Attiva "Modifica" per aggiungere.')),
                                          );
                                          return;
                                        }
                                        _addSkillDialog(
                                          onConfirm: (s) => context.read<ProfileCubit>().addSkillToTeach(s),
                                        );
                                      },
                                      onRemove: (s) {
                                        if (!_isEditing) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Attiva "Modifica" per rimuovere.')),
                                          );
                                          return;
                                        }
                                        final c = context.read<ProfileCubit>();
                                        c.removeSkillToTeach(s);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Rimossa: $s'),
                                            action: SnackBarAction(
                                              label: 'Annulla',
                                              onPressed: () => c.addSkillToTeach(s),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Skills: Wants To Learn
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionTitle(icon: Icons.local_library, title: 'Vuoi imparare'),
                                    const SizedBox(height: 10),
                                    EditableSkillList(
                                      values: u.wantsToLearn,
                                      isEditing: _isEditing,
                                      onAdd: () {
                                        if (!_isEditing) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Attiva "Modifica" per aggiungere.')),
                                          );
                                          return;
                                        }
                                        _addSkillDialog(
                                          onConfirm: (s) => context.read<ProfileCubit>().addSkillToLearn(s),
                                        );
                                      },
                                      onRemove: (s) {
                                        if (!_isEditing) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Attiva "Modifica" per rimuovere.')),
                                          );
                                          return;
                                        }
                                        final c = context.read<ProfileCubit>();
                                        c.removeSkillToLearn(s);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Rimossa: $s'),
                                            action: SnackBarAction(
                                              label: 'Annulla',
                                              onPressed: () => c.addSkillToLearn(s),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Center(
                              child: FilledButton.icon(
                                onPressed: _logout,
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addSkillDialog({required ValueChanged<String> onConfirm}) async {
    if (!_isEditing) return;
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi una competenza'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'Es. Flutter, Chitarra, Cucina giapponese…',
          ),
          onSubmitted: (_) => Navigator.of(context).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Aggiungi')),
        ],
      ),
    );
    if (res == null) return;
    final s = _normalize(res);
    if (s.isEmpty) return;
    onConfirm(s);
  }

  String _normalize(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.imagePath});
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    const double size = 96;
    final imageProvider = (imagePath != null &&
        imagePath!.isNotEmpty &&
        File(imagePath!).existsSync())
        ? FileImage(File(imagePath!)) as ImageProvider
        : const AssetImage('assets/images/logo_no_bg.png');

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [BrandPalette.purple, BrandPalette.magenta, BrandPalette.orange],
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: imageProvider,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: BrandPalette.purple),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
