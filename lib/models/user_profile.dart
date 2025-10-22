
class UserProfile {
  final String id;
  final String userId;
  final String email;
  final String name;
  final int? age;
  final String imageUrl;
  final String bio;
  final List<String> canTeach;
  final List<String> wantsToLearn;
  final List<String> skills;
  final List<String> skillsToLearn;
  final List<String> archivedTeachSkills;
  final List<String> archivedLearnSkills;
  final String location;
  final List<String> languages;
  final bool prefersRemote;
  final bool prefersInPerson;
  final String availability;
  final String timezone;
  final int radiusKm;
  final List<String> badges;
  final bool onboardingCompleted;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.email,
    required this.name,
    this.age,
    this.imageUrl = 'https://via.placeholder.com/600x400',
    this.bio = '',
    this.canTeach = const [],
    this.wantsToLearn = const [],
    this.skills = const [],
    this.skillsToLearn = const [],
    this.archivedTeachSkills = const [],
    this.archivedLearnSkills = const [],
    this.location = '',
    this.languages = const ['IT'],
    this.prefersRemote = true,
    this.prefersInPerson = false,
    this.availability = 'Sera (18–21)',
    this.timezone = 'CET',
    this.radiusKm = 20,
    this.badges = const [],
    this.onboardingCompleted = false,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      userId: map['userId'] ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] is int ? map['age'] : (map['age'] != null ? int.tryParse(map['age'].toString()) : null),
      imageUrl: map['imageUrl'] ?? '',
      bio: map['bio'] ?? '',
      canTeach: List<String>.from(map['canTeach'] ?? []),
      wantsToLearn: List<String>.from(map['wantsToLearn'] ?? []),
      skills: List<String>.from(map['skills'] ?? []),
      skillsToLearn: List<String>.from(map['skillsToLearn'] ?? []),
      archivedTeachSkills:
      List<String>.from(map['archivedTeachSkills'] ?? map['inactiveTeachSkills'] ?? []),
      archivedLearnSkills:
      List<String>.from(map['archivedLearnSkills'] ?? map['inactiveLearnSkills'] ?? []),
      location: map['location'] ?? '',
      languages: List<String>.from(map['languages'] ?? (map['lingue'] ?? ['IT'])),
      prefersRemote: map['prefersRemote'] ?? map['remote'] ?? true,
      prefersInPerson: map['prefersInPerson'] ?? map['inPerson'] ?? false,
      availability: map['availability'] ?? map['tempo'] ?? 'Sera (18–21)',
      timezone: map['timezone'] ?? map['fuso'] ?? 'CET',
      radiusKm: map['radiusKm'] is int
          ? map['radiusKm']
          : int.tryParse(map['radiusKm']?.toString() ?? '') ?? 20,
      badges: List<String>.from(map['badges'] ?? []),
      onboardingCompleted: map['onboardingCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'uid': userId,
      'email': email,
      'name': name,
      'age': age,
      'imageUrl': imageUrl,
      'bio': bio,
      'canTeach': canTeach,
      'wantsToLearn': wantsToLearn,
      'skills': skills,
      'skillsToLearn': skillsToLearn,
      'archivedTeachSkills': archivedTeachSkills,
      'archivedLearnSkills': archivedLearnSkills,
      'location': location,
      'languages': languages,
      'prefersRemote': prefersRemote,
      'prefersInPerson': prefersInPerson,
      'availability': availability,
      'timezone': timezone,
      'radiusKm': radiusKm,
      'badges': badges,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? email,
    String? name,
    int? age,
    String? imageUrl,
    String? bio,
    List<String>? canTeach,
    List<String>? wantsToLearn,
    List<String>? skills,
    List<String>? skillsToLearn,
    List<String>? archivedTeachSkills,
    List<String>? archivedLearnSkills,
    String? location,
    List<String>? languages,
    bool? prefersRemote,
    bool? prefersInPerson,
    String? availability,
    String? timezone,
    int? radiusKm,
    List<String>? badges,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      canTeach: canTeach ?? this.canTeach,
      wantsToLearn: wantsToLearn ?? this.wantsToLearn,
      skills: skills ?? this.skills,
      skillsToLearn: skillsToLearn ?? this.skillsToLearn,
      archivedTeachSkills: archivedTeachSkills ?? this.archivedTeachSkills,
      archivedLearnSkills: archivedLearnSkills ?? this.archivedLearnSkills,
      location: location ?? this.location,
      languages: languages ?? this.languages,
      prefersRemote: prefersRemote ?? this.prefersRemote,
      prefersInPerson: prefersInPerson ?? this.prefersInPerson,
      availability: availability ?? this.availability,
      timezone: timezone ?? this.timezone,
      radiusKm: radiusKm ?? this.radiusKm,
      badges: badges ?? this.badges,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  UserProfile toggleTeachSkill(String skillName) {
    final result = _toggleSkillLists(
      active: canTeach,
      archived: archivedTeachSkills,
      skillName: skillName,
    );
    return copyWith(
      canTeach: result.active,
      archivedTeachSkills: result.archived,
    );
  }

  UserProfile toggleLearnSkill(String skillName) {
    final result = _toggleSkillLists(
      active: wantsToLearn,
      archived: archivedLearnSkills,
      skillName: skillName,
    );
    return copyWith(
      wantsToLearn: result.active,
      archivedLearnSkills: result.archived,
    );
  }

  UserProfile addTeachSkill(String skillName) {
    final result = _addSkill(
      active: canTeach,
      archived: archivedTeachSkills,
      skillName: skillName,
    );
    return copyWith(
      canTeach: result.active,
      archivedTeachSkills: result.archived,
    );
  }

  UserProfile addLearnSkill(String skillName) {
    final result = _addSkill(
      active: wantsToLearn,
      archived: archivedLearnSkills,
      skillName: skillName,
    );
    return copyWith(
      wantsToLearn: result.active,
      archivedLearnSkills: result.archived,
    );
  }

  @override
  String toString() {
    final segments = <String>['UserProfile✨'];
    _appendDetail(segments, 'id', id);
    _appendDetail(segments, 'userId', userId);
    _appendDetail(segments, 'email', email);
    _appendDetail(segments, 'name', name);
    _appendDetail(segments, 'age', age);
    _appendDetail(segments, 'location', location);
    _appendDetail(
        segments, 'languages', languages.isEmpty ? null : languages.join('/'));
    _appendDetail(
        segments, 'teach', canTeach.isEmpty ? null : canTeach.join(', '));
    _appendDetail(
        segments, 'learn', wantsToLearn.isEmpty ? null : wantsToLearn.join(', '));
    _appendDetail(segments, 'remote', prefersRemote);
    _appendDetail(segments, 'inPerson', prefersInPerson);
    _appendDetail(segments, 'availability', availability);
    _appendDetail(segments, 'tz', timezone);
    _appendDetail(segments, 'radius', '${radiusKm}km');
    _appendDetail(
        segments, 'badges', badges.isEmpty ? null : badges.join(', '));
    _appendDetail(segments, 'onboarded', onboardingCompleted);
    return segments.join(' · ');
  }
}

({List<String> active, List<String> archived}) _toggleSkillLists({
  required List<String> active,
  required List<String> archived,
  required String skillName,
}) {
  final normalized = _normalizeSkill(skillName);
  final currentActive = List<String>.from(active);
  final currentArchived = List<String>.from(archived);
  if (normalized.isEmpty) {
    return (active: currentActive, archived: currentArchived);
  }

  final activeIndex = _matchIndex(currentActive, normalized);
  if (activeIndex != -1) {
    currentActive.removeAt(activeIndex);
    return (
    active: _dedupeSkills(currentActive),
    archived: _dedupeSkills(currentArchived),
    );
  }

  final archivedIndex = _matchIndex(currentArchived, normalized);
  if (archivedIndex != -1) {
    currentActive.add(currentArchived.removeAt(archivedIndex));
  } else {
    currentActive.add(normalized);
  }

  return (
  active: _dedupeSkills(currentActive),
  archived: _dedupeSkills(currentArchived),
  );
}

({List<String> active, List<String> archived}) _addSkill({
  required List<String> active,
  required List<String> archived,
  required String skillName,
}) {
  final normalized = _normalizeSkill(skillName);
  final currentActive = List<String>.from(active);
  final currentArchived = List<String>.from(archived);
  if (normalized.isEmpty) {
    return (active: currentActive, archived: currentArchived);
  }

  final archivedIndex = _matchIndex(currentArchived, normalized);
  if (archivedIndex != -1) {
    currentActive.add(currentArchived.removeAt(archivedIndex));
  } else if (_matchIndex(currentActive, normalized) == -1) {
    currentActive.add(normalized);
  }

  return (
  active: _dedupeSkills(currentActive),
  archived: _dedupeSkills(currentArchived),
  );
}

int _matchIndex(List<String> values, String candidate) {
  final normalized = candidate.toLowerCase();
  return values.indexWhere((value) => value.toLowerCase() == normalized);
}

String _normalizeSkill(String value) => value.trim();

List<String> _dedupeSkills(List<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    final key = normalized.toLowerCase();
    if (normalized.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    result.add(normalized);
  }
  return result;
}

void _appendDetail(List<String> segments, String label, Object? value) {
  if (value == null) return;
  if (value is bool) {
    if (!value) return;
    segments.add(label);
    return;
  }
  if (value is Iterable && value.isEmpty) return;
  if (value is String && value.isEmpty) return;
  segments.add('$label=$value');
}