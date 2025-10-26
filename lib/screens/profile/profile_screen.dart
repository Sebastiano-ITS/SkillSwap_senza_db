import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../data/local_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/brand_palette.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _user;
  bool _loading = true;
  String? _error;

  // Controller per i campi modificabili
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  double _radiusKm = 3;
  String? _birthIso;

  @override
  void initState() {
    super.initState();
    final u = LocalData().getUserById(widget.userId);
    if (u == null) {
      setState(() {
        _error = 'Profilo non trovato.';
        _loading = false;
      });
    } else {
      _user = u;
      _nameCtrl.text = u.name;
      _emailCtrl.text = u.email;
      _phoneCtrl.text = u.phone ?? '';
      _cityCtrl.text = u.city ?? '';
      _radiusKm = u.radiusKm ?? 3;
      _bioCtrl.text = u.bio ?? '';
      _birthIso = u.birthDateIso;
      _loading = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveUser(UserProfile updated) async {
    await LocalData().saveUser(updated);
    setState(() => _user = updated);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${appDir.path}/skillswap/avatars');
    if (!await dir.exists()) await dir.create(recursive: true);

    final String ext = file.path.split('.').last;
    final String targetPath = '${dir.path}/${_user!.id}.$ext';
    await File(file.path).copy(targetPath);

    final updated = _user!.copyWith(localImages: [targetPath]);
    await _saveUser(updated);
    await _saveUser(updated);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthIso != null ? DateTime.tryParse(_birthIso!) ?? DateTime(now.year - 18) : DateTime(now.year - 18);
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
      setState(() => _birthIso = picked.toIso8601String().substring(0, 10));
      await _persistBasics(); // salva subito
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

  Future<void> _addSkill({required bool teach}) async {
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(teach ? 'Aggiungi una competenza che puoi insegnare' : 'Aggiungi una competenza che vuoi imparare'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Es. Flutter, Chitarra, Cucina giapponese…'),
          onSubmitted: (_) => Navigator.pop(context, controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Aggiungi')),
        ],
      ),
    );
    if (res == null || res.trim().isEmpty) return;

    String normalized(String s) {
      final t = s.trim();
      if (t.isEmpty) return t;
      return t[0].toUpperCase() + t.substring(1);
    }

    final skill = normalized(res);
    final teachList = List<String>.from(_user!.canTeach);
    final learnList = List<String>.from(_user!.wantsToLearn);

    if (teach) {
      if (!teachList.contains(skill)) teachList.add(skill);
    } else {
      if (!learnList.contains(skill)) learnList.add(skill);
    }

    final updated = _user!.copyWith(canTeach: teachList..sort(), wantsToLearn: learnList..sort());
    await _saveUser(updated);
  }

  Future<void> _removeSkill(String skill, {required bool teach}) async {
    final teachList = List<String>.from(_user!.canTeach);
    final learnList = List<String>.from(_user!.wantsToLearn);

    if (teach) {
      teachList.remove(skill);
    } else {
      learnList.remove(skill);
    }
    final updated = _user!.copyWith(canTeach: teachList, wantsToLearn: learnList);
    await _saveUser(updated);
  }

  void _logout() {
    context.read<AuthService>().signOut();
    LocalData().signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(appBar: AppBar(title: const Text('Profilo')), body: Center(child: Text(_error!)));
    }

    final theme = Theme.of(context);
    final u = _user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background coerente con il progetto
          Positioned.fill(child: Image.asset('assets/images/background_color.png', fit: BoxFit.cover)),
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
                      // Header: Avatar + nome/email azionabili
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar con pulsante cambio
                              Stack(
                                children: [
                                  _Avatar(imagePath: u.localImages.isNotEmpty ? u.localImages.first : null),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: InkWell(
                                      onTap: _pickAvatar,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.edit, size: 16, color: BrandPalette.purple),
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
                                      decoration: _decor('Nome'),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: _decor('Email'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Info di contatto e localizzazione
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(icon: Icons.badge_outlined, title: 'Informazioni di base'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: _decor('Cellulare'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _pickBirthDate,
                                      child: AbsorbPointer(
                                        child: TextField(
                                          decoration: _decor('Data di nascita'),
                                          controller: TextEditingController(
                                            text: _birthIso ?? '',
                                          ),
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
                                      decoration: _decor('Città'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Raggio (km): ${_radiusKm.round()}',
                                            style: theme.textTheme.labelLarge),
                                        Slider(
                                          value: _radiusKm,
                                          min: 1,
                                          max: 50,
                                          divisions: 49,
                                          activeColor: BrandPalette.magenta,
                                          thumbColor: BrandPalette.orange,
                                          label: '${_radiusKm.round()}',
                                          onChanged: (v) => setState(() => _radiusKm = v),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: BrandPalette.purple),
                                  onPressed: _persistBasics,
                                  child: const Text('Salva informazioni'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Bio
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(icon: Icons.notes, title: 'Bio'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _bioCtrl,
                                maxLines: 5,
                                minLines: 4,
                                decoration: _decor('Scrivi una breve bio…'),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: BrandPalette.purple),
                                  onPressed: _persistBasics,
                                  child: const Text('Salva bio'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Skills: Can Teach
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(icon: Icons.school, title: 'Puoi insegnare'),
                              const SizedBox(height: 10),
                              _EditableChips(
                                values: u.canTeach,
                                onAdd: () => _addSkill(teach: true),
                                onTapRemove: (s) => _removeSkill(s, teach: true),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Skills: Wants To Learn
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(icon: Icons.local_library, title: 'Vuoi imparare'),
                              const SizedBox(height: 10),
                              _EditableChips(
                                values: u.wantsToLearn,
                                onAdd: () => _addSkill(teach: false),
                                onTapRemove: (s) => _removeSkill(s, teach: false),
                              ),
                            ],
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BrandPalette.purple, width: 1.4),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.imagePath});
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    const double size = 96;
    final imageProvider = (imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync())
        ? FileImage(File(imagePath!)) as ImageProvider
        : const AssetImage('assets/images/logo_no_bg.png');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [BrandPalette.purple, BrandPalette.magenta, BrandPalette.orange]),
      ),
      padding: const EdgeInsets.all(3),
      child: CircleAvatar(backgroundColor: Colors.white, backgroundImage: imageProvider),
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
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _EditableChips extends StatelessWidget {
  const _EditableChips({
    required this.values,
    required this.onAdd,
    required this.onTapRemove,
  });

  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<String> onTapRemove;

  @override
  Widget build(BuildContext context) {
    final items = [...values]..sort();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final s in items)
          InkWell(
            onTap: () => onTapRemove(s), // tap per rimuovere
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: BrandPalette.purple.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: BrandPalette.purple, width: 1.2),
              ),
              child: Text(s, style: const TextStyle(color: BrandPalette.purple, fontWeight: FontWeight.w600)),
            ),
          ),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18, color: BrandPalette.purple),
          label: const Text('Aggiungi', style: TextStyle(color: BrandPalette.purple)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: BrandPalette.purple, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            foregroundColor: BrandPalette.purple,
          ),
        ),
      ],
    );
  }
}
