import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../flutter_bloc/profile_bloc/profile_cubit.dart';
import '../../flutter_bloc/profile_bloc/profile_state.dart';
import '../../models/user_profile.dart';
import 'profile_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ProfileCubit(repository: LocalProfileRepository())..loadProfile(userId),
      child: _ProfileView(userId: userId),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView({required this.userId});

  final String userId;

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _teachSkillController;
  late final TextEditingController _learnSkillController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _teachSkillController = TextEditingController();
    _learnSkillController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _teachSkillController.dispose();
    _learnSkillController.dispose();
    super.dispose();
  }

  void _syncControllers(UserProfile profile) {
    _nameController.text = profile.name;
    _emailController.text = profile.email;
  }

  void _handleAddSkill({required bool teach}) {
    final cubit = context.read<ProfileCubit>();
    if (teach) {
      final text = _teachSkillController.text.trim();
      if (text.isEmpty) return;
      cubit.addSkillToTeach(text);
      _teachSkillController.clear();
    } else {
      final text = _learnSkillController.text.trim();
      if (text.isEmpty) return;
      cubit.addSkillToLearn(text);
      _learnSkillController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) {
        return previous.profile != current.profile ||
            previous.feedbackMessage != current.feedbackMessage ||
            previous.errorMessage != current.errorMessage;
      },
      listener: (context, state) {
        if (state.profile != null) {
          _syncControllers(state.profile!);
        }

        if (state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.feedbackMessage!)),
          );
          context.read<ProfileCubit>().clearMessages();
        }

        if (state.errorMessage != null &&
            state.status == ProfileStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          context.read<ProfileCubit>().clearMessages();
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profilo'),
            actions: [
              BlocBuilder<ProfileCubit, ProfileState>(
                buildWhen: (previous, current) =>
                    previous.hasUnsavedChanges != current.hasUnsavedChanges ||
                    previous.status != current.status,
                builder: (context, currentState) {
                  final isSaving = currentState.status == ProfileStatus.saving;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: FilledButton.icon(
                      onPressed: currentState.hasUnsavedChanges && !isSaving
                          ? () {
                              FocusScope.of(context).unfocus();
                              context.read<ProfileCubit>().saveProfile();
                            }
                          : null,
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.save),
                      label: Text(isSaving ? 'Salvataggio...' : 'Salva'),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _buildBody(context, state, theme),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, ProfileState state, ThemeData theme) {
    if (state.status == ProfileStatus.loading ||
        (state.status == ProfileStatus.initial && state.profile == null)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ProfileStatus.failure && state.profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertTriangle,
                size: 36, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(state.errorMessage ?? 'Si è verificato un errore'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  context.read<ProfileCubit>().loadProfile(widget.userId),
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(theme, profile),
          const SizedBox(height: 16),
          _buildUserInfoCard(theme, profile),
          const SizedBox(height: 16),
          if (state.hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hai modifiche non salvate.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Nome',
            controller: _nameController,
            icon: LucideIcons.user,
            onChanged: context.read<ProfileCubit>().updateName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email',
            controller: _emailController,
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            onChanged: context.read<ProfileCubit>().updateEmail,
          ),
          const SizedBox(height: 24),
          _buildSkillSection(
            title: 'Cosa posso insegnare',
            color: Colors.indigo,
            skills: profile.canTeach,
            controller: _teachSkillController,
            placeholder: 'Aggiungi una competenza',
            onAdd: () => _handleAddSkill(teach: true),
            onRemove: context.read<ProfileCubit>().removeSkillToTeach,
          ),
          const SizedBox(height: 24),
          _buildSkillSection(
            title: 'Cosa voglio imparare',
            color: Colors.orange,
            skills: profile.wantsToLearn,
            controller: _learnSkillController,
            placeholder: 'Aggiungi una competenza da imparare',
            onAdd: () => _handleAddSkill(teach: false),
            onRemove: context.read<ProfileCubit>().removeSkillToLearn,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, UserProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                style:
                    theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.name,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              profile.email,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme, UserProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.badgeCheck, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('ID Utente', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(
              profile.id,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSkillSection({
    required String title,
    required Color color,
    required List<String> skills,
    required TextEditingController controller,
    required String placeholder,
    required VoidCallback onAdd,
    required ValueChanged<String> onRemove,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.star, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: placeholder,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(LucideIcons.plus),
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              Text(
                'Nessuna competenza inserita.',
                style: TextStyle(
                    color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => onRemove(skill),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
