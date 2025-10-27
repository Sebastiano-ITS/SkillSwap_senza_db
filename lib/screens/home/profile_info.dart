import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../theme/brand_palette.dart';

class ProfileInfo extends StatefulWidget {
  final UserProfile profile;
  const ProfileInfo({super.key, required this.profile});

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrowCtrl;
  final ScrollController _scrollCtrl = ScrollController();
  bool _showArrow = false;

  @override
  void initState() {
    super.initState();
    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Aggiorna la visibilità della freccia quando cambia lo scroll
    _scrollCtrl.addListener(_updateArrowVisibility);

    // calcola se c’è overflow per decidere se mostrare la freccia
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrowVisibility());
  }

  void _updateArrowVisibility() {
    final canScroll = _scrollCtrl.position.maxScrollExtent > 0;
    final atBottom = _scrollCtrl.offset >= _scrollCtrl.position.maxScrollExtent - 2;
    final shouldShow = canScroll && !atBottom;
    if (_showArrow != shouldShow && mounted) {
      setState(() => _showArrow = shouldShow);
    }
  }

  @override
  void dispose() {
    _arrowCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    // Location preferita + fallback legacy
    final city = profile.location ?? profile.city ?? 'Località sconosciuta';
    final distance = profile.distanceKm ?? profile.radiusKm;
    final distanceText = distance != null ? '${distance.toStringAsFixed(1)} km da te' : '';
    final age = profile.age != null ? ', ${profile.age}' : '';

    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Stack(
          children: [
            // Contenuto scrollabile
            SingleChildScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome + età
                  Text(
                    '${profile.name}$age',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Città + distanza
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$city${distanceText.isNotEmpty ? " — $distanceText" : ""}',
                          style: tt.bodySmall?.copyWith(
                            color: Colors.black54,
                            height: 1.35,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Skills che può insegnare
                  if (profile.canTeach.isNotEmpty) ...[
                    _SectionTitle(
                      icon: Icons.school,
                      title: 'Skills che può insegnare',
                    ),
                    const SizedBox(height: 6),
                    _SkillWrap(
                      skills: profile.canTeach,
                      chipColor: BrandPalette.magenta,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Skills che vuole imparare
                  if (profile.wantsToLearn.isNotEmpty) ...[
                    _SectionTitle(
                      icon: Icons.local_library,
                      title: 'Skills che vuole imparare',
                    ),
                    const SizedBox(height: 6),
                    _SkillWrap(
                      skills: profile.wantsToLearn,
                      chipColor: BrandPalette.orange,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Bio
                  if ((profile.bio ?? '').isNotEmpty) ...[
                    _SectionTitle(icon: Icons.notes, title: 'Bio'),
                    const SizedBox(height: 6),
                    Text(
                      profile.bio!,
                      style: tt.bodyMedium?.copyWith(
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),

            // Freccia animata
            if (_showArrow)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _arrowCtrl,
                    builder: (context, _) {
                      final offsetY = 4 * _arrowCtrl.value;
                      final opacity = 0.5 + 0.5 * (1 - (_arrowCtrl.value - 0.5).abs() * 2);
                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, offsetY),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black38,
                            size: 26,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
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
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, color: BrandPalette.purple, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _SkillWrap extends StatelessWidget {
  const _SkillWrap({required this.skills, required this.chipColor});
  final List<String> skills;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: skills.map((s) {
        return Chip(
          label: Text(
            s,
            style: tt.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: chipColor,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        );
      }).toList(),
    );
  }
}