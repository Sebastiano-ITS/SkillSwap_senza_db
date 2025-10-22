import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:getwidget/getwidget.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skillswap/models/user_profile.dart';
import 'package:skillswap/screens/profile/profile_auth.dart';
import 'package:skillswap/screens/profile/profile_palette.dart';
import 'package:skillswap/screens/profile/profile_repository.dart';
import 'package:skillswap/screens/profile/profile_state.dart';
import 'package:skillswap/screens/profile/skill_category.dart';
import 'package:skillswap/services/auth_service.dart';
import 'package:skillswap/services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.userProfile, this.userId});

  final UserProfile? userProfile;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final palette = ProfilePalette();

    return BlocProvider(
      create: (_) => ProfileCubit(
        repository: FirestoreProfileRepository(firestore),
        authService: AuthServiceProfileAuth(auth),
      )..load(userId: userId, fallback: userProfile),
      child: ProfileView(palette: palette, authService: auth),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.palette, required this.authService});

  final ProfilePalette palette;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state.status == ProfileStatus.failure) {
          return _ProfileError(message: state.errorMessage ?? 'Errore sconosciuto', palette: palette);
        }
        if (state.status == ProfileStatus.loaded && state.profile != null) {
          return _ProfileScaffold(palette: palette, state: state, authService: authService);
        }
        return _ProfileLoading(palette: palette);
      },
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading({required this.palette});

  final ProfilePalette palette;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Profilo'),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: palette.headerGradient)),
      ),
      body: Center(child: CircularProgressIndicator(color: palette.primary)),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.palette});

  final String message;
  final ProfilePalette palette;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Profilo'),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: palette.headerGradient)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle, color: palette.warning, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: palette.textPrimary, fontSize: 16)),
            const SizedBox(height: 16),
            GFButton(
              onPressed: () => context.read<ProfileCubit>().load(),
              text: 'Riprova',
              color: palette.primary,
              shape: GFButtonShape.pills,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileScaffold extends StatelessWidget {
  const _ProfileScaffold({required this.palette, required this.state, required this.authService});

  final ProfilePalette palette;
  final ProfileState state;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile!;
    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: palette.headerGradient)),
        title: const Text('Profilo', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GFButton(
              onPressed: () async {
                await authService.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Logout completato'), backgroundColor: palette.warning),
                  );
                  context.go('/login');
                }
              },
              text: 'Logout',
              icon: const Icon(LucideIcons.logOut, color: Colors.white, size: 18),
              color: palette.warning,
              shape: GFButtonShape.pills,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(palette: palette, profile: profile),
            const SizedBox(height: 20),
            _ActionRow(palette: palette, profile: profile),
            const SizedBox(height: 20),
            _BioCard(palette: palette, profile: profile),
            const SizedBox(height: 20),
            _SkillSection(palette: palette, title: 'Insegno', icon: LucideIcons.lightbulb, category: SkillCategory.teach, skills: profile.canTeach),
            const SizedBox(height: 20),
            _SkillSection(palette: palette, title: 'Voglio imparare', icon: LucideIcons.bookOpen, category: SkillCategory.learn, skills: profile.wantsToLearn),
            const SizedBox(height: 20),
            _PreferencesCard(palette: palette, profile: profile),
            const SizedBox(height: 20),
            _VisibilityCard(palette: palette, state: state),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.palette, required this.profile});

  final ProfilePalette palette;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final username = profile.email.contains('@')
        ? '@${profile.email.split('@').first}'
        : '@${profile.userId.substring(0, profile.userId.length.clamp(0, 8))}';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: palette.borderColor.withOpacity(0.15), blurRadius: 22, offset: const Offset(0, 12))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(palette: palette, profile: profile),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: TextStyle(color: palette.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(username, style: TextStyle(color: palette.textMuted)),
                const SizedBox(height: 8),
                Text(profile.location.isEmpty ? 'Aggiorna la tua posizione' : profile.location, style: TextStyle(color: palette.textSecondary)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _StatChip(icon: LucideIcons.star, label: '4.9'),
                    _StatChip(icon: LucideIcons.users, label: '32 match'),
                    _StatChip(icon: LucideIcons.calendarCheck, label: '18 sessioni'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.palette, required this.profile});

  final ProfilePalette palette;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: palette.chipBackground,
          backgroundImage: profile.imageUrl.isEmpty ? null : NetworkImage(profile.imageUrl),
          child: profile.imageUrl.isEmpty
              ? Text(profile.name.isEmpty ? 'U' : profile.name[0].toUpperCase(), style: TextStyle(color: palette.primary, fontSize: 28, fontWeight: FontWeight.bold))
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _openAvatarSheet(context, profile),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: palette.primary,
              child: const Icon(LucideIcons.camera, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAvatarSheet(BuildContext context, UserProfile profile) async {
    final controller = TextEditingController(text: profile.imageUrl);
    final palette = this.palette;
    final newUrl = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aggiorna foto profilo', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              TextField(controller: controller, decoration: const InputDecoration(labelText: 'URL immagine')),
              const SizedBox(height: 12),
              GFButton(
                onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                text: 'Salva',
                color: palette.primary,
                shape: GFButtonShape.pills,
              ),
            ],
          ),
        );
      },
    );
    if (newUrl == null || newUrl.isEmpty) return;
    if (!context.mounted) return;
    final cubit = context.read<ProfileCubit>();
    final updated = profile.copyWith(imageUrl: newUrl);
    await cubit.updateProfile(updated);
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.palette, required this.profile});

  final ProfilePalette palette;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        GFButton(
          onPressed: () => _openEditor(context, profile),
          text: 'Modifica profilo',
          icon: const Icon(LucideIcons.pencil, color: Colors.white, size: 18),
          color: palette.primary,
          shape: GFButtonShape.pills,
        ),
        GFButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('La ricerca match arriverà presto!'), backgroundColor: palette.accent),
            );
          },
          text: 'Trova match',
          icon: const Icon(LucideIcons.sparkle, color: Colors.white, size: 18),
          color: palette.primary,
          shape: GFButtonShape.pills,
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, UserProfile profile) async {
    final result = await showModalBottomSheet<UserProfile>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProfileEditorSheet(profile: profile, palette: palette),
    );
    if (result == null) return;
    if (!context.mounted) return;
    await context.read<ProfileCubit>().updateProfile(result);
  }
}

class _BioCard extends StatelessWidget {
  const _BioCard({required this.palette, required this.profile});

  final ProfilePalette palette;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: palette.cardColor, borderRadius: BorderRadius.circular(24)),
      child: Text(
        profile.bio.isEmpty
            ? 'Racconta alla community qualcosa di te, delle tue passioni e del tuo stile di apprendimento.'
            : profile.bio,
        style: TextStyle(color: palette.textPrimary, fontSize: 16, height: 1.4),
      ),
    );
  }
}

class _SkillSection extends StatelessWidget {
  const _SkillSection({
    required this.palette,
    required this.title,
    required this.icon,
    required this.category,
    required this.skills,
  });

  final ProfilePalette palette;
  final String title;
  final IconData icon;
  final SkillCategory category;
  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: palette.cardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: palette.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              GFButton(
                onPressed: () => _openSkillComposer(context),
                text: 'Aggiungi',
                icon: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                color: palette.primary,
                size: GFSize.SMALL,
                shape: GFButtonShape.pills,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (skills.isEmpty)
            Text('Nessuna competenza. Usa il tasto + per aggiungerne una.', style: TextStyle(color: palette.textMuted))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: skills
                  .map(
                    (skill) => GFButton(
                  onPressed: () => context.read<ProfileCubit>().toggleSkill(category, skill),
                  text: skill,
                  icon: const Icon(LucideIcons.minusCircle, color: Colors.white, size: 16),
                  color: palette.primary,
                  size: GFSize.SMALL,
                  shape: GFButtonShape.pills,
                ),
              )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _openSkillComposer(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _SkillComposer(category: category, palette: palette),
    );
    if (result == null || result.isEmpty) return;
    if (!context.mounted) return;
    await context.read<ProfileCubit>().addSkill(category, result);
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.palette, required this.profile});

  final ProfilePalette palette;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: palette.cardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferenze di scambio', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (profile.prefersRemote)
                _PreferenceChip(label: 'Remoto', icon: LucideIcons.monitor, palette: palette),
              if (profile.prefersInPerson)
                _PreferenceChip(label: 'In presenza', icon: LucideIcons.mapPin, palette: palette),
            ],
          ),
          const SizedBox(height: 12),
          _PreferenceRow(label: 'Lingue', value: profile.languages.join(', '), palette: palette),
          _PreferenceRow(label: 'Tempo', value: profile.availability, palette: palette),
          _PreferenceRow(label: 'Fuso', value: profile.timezone, palette: palette),
          _PreferenceRow(label: 'Raggio', value: '${profile.radiusKm} km', palette: palette),
        ],
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({required this.palette, required this.state});

  final ProfilePalette palette;
  final ProfileState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: palette.cardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _VisibilityRow(
            title: 'Profilo pubblico',
            subtitle: 'Consenti alla community di scoprire il tuo profilo.',
            value: state.isPublic,
            icon: LucideIcons.shieldCheck,
            palette: palette,
            onChanged: (value) => context.read<ProfileCubit>().updateVisibility(isPublic: value),
          ),
          Divider(color: palette.borderColor.withOpacity(0.3)),
          _VisibilityRow(
            title: 'Disponibile a nuovi match',
            subtitle: 'Permetti agli altri di contattarti.',
            value: state.acceptsMatches,
            icon: LucideIcons.radar,
            palette: palette,
            onChanged: (value) => context.read<ProfileCubit>().updateVisibility(acceptsMatches: value),
          ),
        ],
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({required this.label, required this.icon, required this.palette});

  final String label;
  final IconData icon;
  final ProfilePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: palette.chipBackground, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: palette.primary, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.label, required this.value, required this.palette});

  final String label;
  final String value;
  final ProfilePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('$label:', style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: palette.textPrimary))),
        ],
      ),
    );
  }
}

class _VisibilityRow extends StatelessWidget {
  const _VisibilityRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.palette,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ProfilePalette palette;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: palette.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: palette.textMuted, height: 1.3)),
            ],
          ),
        ),
        GFToggle(
          value: value,
          onChanged: adaptToggleOnChanged(
            onChanged: onChanged,
            fallbackValue: value,
          ),
          enabledTrackColor: palette.primary,
          disabledTrackColor: palette.chipBackground,
          enabledThumbColor: Colors.white,
          disabledThumbColor: palette.textMuted,
          type: GFToggleType.android,
        ),
      ],
    );
  }
}

ValueChanged<bool?> adaptToggleOnChanged({
  required ValueChanged<bool> onChanged,
  required bool fallbackValue,
}) {
  return (value) => onChanged(value ?? fallbackValue);
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD57E), Color(0xFFFFA24C)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF640D5F)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SkillComposer extends StatefulWidget {
  const _SkillComposer({required this.category, required this.palette});

  final SkillCategory category;
  final ProfilePalette palette;

  @override
  State<_SkillComposer> createState() => _SkillComposerState();
}

class _SkillComposerState extends State<_SkillComposer> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.category == SkillCategory.teach
        ? const ['UI Design', 'Figma', 'Leadership']
        : const ['SwiftUI', 'Motion Design', 'Spagnolo'];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aggiungi competenza', style: TextStyle(color: widget.palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((skill) => ChoiceChip(
              label: Text(skill),
              selected: controller.text.trim().toLowerCase() == skill.toLowerCase(),
              onSelected: (_) => setState(() => controller.text = skill),
            ))
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nome competenza'),
          ),
          const SizedBox(height: 12),
          GFButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            text: 'Aggiungi',
            color: widget.palette.primary,
            shape: GFButtonShape.pills,
            fullWidthButton: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileEditorSheet extends StatefulWidget {
  const _ProfileEditorSheet({required this.profile, required this.palette});

  final UserProfile profile;
  final ProfilePalette palette;

  @override
  State<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<_ProfileEditorSheet> {
  late final TextEditingController nameController;
  late final TextEditingController locationController;
  late final TextEditingController bioController;
  late final TextEditingController languagesController;
  late final TextEditingController availabilityController;
  late final TextEditingController timezoneController;
  late final TextEditingController radiusController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profile.name);
    locationController = TextEditingController(text: widget.profile.location);
    bioController = TextEditingController(text: widget.profile.bio);
    languagesController = TextEditingController(text: widget.profile.languages.join(', '));
    availabilityController = TextEditingController(text: widget.profile.availability);
    timezoneController = TextEditingController(text: widget.profile.timezone);
    radiusController = TextEditingController(text: widget.profile.radiusKm.toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    bioController.dispose();
    languagesController.dispose();
    availabilityController.dispose();
    timezoneController.dispose();
    radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifica profilo', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _TextField(label: 'Nome e Cognome', controller: nameController),
            _TextField(label: 'Città, Paese', controller: locationController),
            _TextField(label: 'Bio', controller: bioController, maxLines: 3),
            _TextField(label: 'Lingue (separate da virgola)', controller: languagesController),
            _TextField(label: 'Disponibilità', controller: availabilityController),
            _TextField(label: 'Fuso orario', controller: timezoneController),
            _TextField(label: 'Raggio (km)', controller: radiusController, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            GFButton(
              onPressed: () {
                final languages = languagesController.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList();
                Navigator.of(context).pop(widget.profile.copyWith(
                  name: nameController.text.trim(),
                  location: locationController.text.trim(),
                  bio: bioController.text.trim(),
                  languages: languages.isEmpty ? widget.profile.languages : languages,
                  availability: availabilityController.text.trim(),
                  timezone: timezoneController.text.trim(),
                  radiusKm: int.tryParse(radiusController.text.trim()) ?? widget.profile.radiusKm,
                ));
              },
              text: 'Salva',
              color: palette.primary,
              shape: GFButtonShape.pills,
              fullWidthButton: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.label, required this.controller, this.maxLines = 1, this.keyboardType});

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}