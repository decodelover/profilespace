/// Onboarding Screen 2 — Dynamic Profile Form
///
/// Collects user details dynamically based on their specialization/role choice.
/// Implements background local caching using FlutterSecureStorage.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/domain/entities.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

class ProjectInput {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final urlController = TextEditingController();
  final skillsController = TextEditingController();
  final imageController = TextEditingController();

  ProjectInput({
    String title = '',
    String desc = '',
    String url = '',
    String skills = '',
    String image = '',
  }) {
    titleController.text = title;
    descController.text = desc;
    urlController.text = url;
    skillsController.text = skills;
    imageController.text = image;
  }

  void dispose() {
    titleController.dispose();
    descController.dispose();
    urlController.dispose();
    skillsController.dispose();
    imageController.dispose();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': titleController.text.trim(),
      'description': descController.text.trim(),
      'url': urlController.text.trim(),
      'skills': skillsController.text
          .trim()
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'image_url': imageController.text.trim(),
    };
  }
}

class DetailsFormScreen extends StatefulWidget {
  const DetailsFormScreen({super.key});

  @override
  State<DetailsFormScreen> createState() => _DetailsFormScreenState();
}

class _DetailsFormScreenState extends State<DetailsFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _photoUrlController = TextEditingController();

  // Dynamic Fields based on Role
  final _gitLinkController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _socialLinkController = TextEditingController();

  final String _layoutTemplate = 'minimal_dark';
  String _selectedColor = '#6366F1'; // Default Indigo

  final List<ProjectInput> _projects = [];

  // Accent Color Options
  final List<Map<String, String>> _colorOptions = [
    {'name': 'Indigo', 'hex': '#6366F1'},
    {'name': 'Emerald', 'hex': '#10B981'},
    {'name': 'Amber', 'hex': '#F59E0B'},
    {'name': 'Cyan', 'hex': '#06B6D4'},
    {'name': 'Rose', 'hex': '#EC4899'},
  ];

  late final AnimationController _auroraController;
  bool _didInit = false;

  ProfessionalRole get _role {
    final roleParam =
        GoRouterState.of(context).uri.queryParameters['role'] ?? 'developer';
    return ProfessionalRole.values.firstWhere(
      (r) => r.name == roleParam,
      orElse: () => ProfessionalRole.developer,
    );
  }

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Default project load
    _addProject(
      title: 'Personal Portfolio App',
      desc: 'Showcasing bento items with responsive web layouts.',
      url: 'https://tspace.me',
      skills: 'Flutter, Dart, CSS',
      image:
          'https://images.unsplash.com/photo-1550745165-9bc0b252726f?q=80&w=600',
    );

    // Initialize Local Cache listeners
    _setupCachingListeners();
    _loadCachedData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _titleController.text = switch (_role) {
        ProfessionalRole.developer => 'Software Engineer',
        ProfessionalRole.designer => 'UI/UX Designer',
        ProfessionalRole.photographer => 'Visual Artist',
        ProfessionalRole.writer => 'Technical Writer',
        ProfessionalRole.videographer => 'Video Producer',
        ProfessionalRole.musician => 'Composer / Songwriter',
        ProfessionalRole.marketer => 'Growth Marketer',
        ProfessionalRole.consultant => 'Business Consultant',
      };
      _photoUrlController.text =
          'https://ui-avatars.com/api/?name=User&background=6366F1&color=fff';
    }
  }

  void _setupCachingListeners() {
    final storage = sl<FlutterSecureStorage>();
    _nameController.addListener(() {
      storage.write(key: 'onboarding_name', value: _nameController.text);
    });
    _titleController.addListener(() {
      storage.write(key: 'onboarding_title', value: _titleController.text);
    });
    _bioController.addListener(() {
      storage.write(key: 'onboarding_bio', value: _bioController.text);
    });
    _skillsController.addListener(() {
      storage.write(key: 'onboarding_skills', value: _skillsController.text);
    });
    _photoUrlController.addListener(() {
      storage.write(key: 'onboarding_photo', value: _photoUrlController.text);
    });
    _gitLinkController.addListener(() {
      storage.write(key: 'onboarding_git', value: _gitLinkController.text);
    });
    _specialtyController.addListener(() {
      storage.write(
        key: 'onboarding_specialty',
        value: _specialtyController.text,
      );
    });
    _socialLinkController.addListener(() {
      storage.write(
        key: 'onboarding_social',
        value: _socialLinkController.text,
      );
    });
  }

  Future<void> _loadCachedData() async {
    try {
      final storage = sl<FlutterSecureStorage>();
      final cachedName = await storage.read(key: 'onboarding_name');
      final cachedTitle = await storage.read(key: 'onboarding_title');
      final cachedBio = await storage.read(key: 'onboarding_bio');
      final cachedSkills = await storage.read(key: 'onboarding_skills');
      final cachedPhoto = await storage.read(key: 'onboarding_photo');
      final cachedGit = await storage.read(key: 'onboarding_git');
      final cachedSpecialty = await storage.read(key: 'onboarding_specialty');
      final cachedSocial = await storage.read(key: 'onboarding_social');

      if (mounted) {
        setState(() {
          if (cachedName != null && cachedName.isNotEmpty) {
            _nameController.text = cachedName;
          }
          if (cachedTitle != null && cachedTitle.isNotEmpty) {
            _titleController.text = cachedTitle;
          }
          if (cachedBio != null && cachedBio.isNotEmpty) {
            _bioController.text = cachedBio;
          }
          if (cachedSkills != null && cachedSkills.isNotEmpty) {
            _skillsController.text = cachedSkills;
          }
          if (cachedPhoto != null && cachedPhoto.isNotEmpty) {
            _photoUrlController.text = cachedPhoto;
          }
          if (cachedGit != null && cachedGit.isNotEmpty) {
            _gitLinkController.text = cachedGit;
          }
          if (cachedSpecialty != null && cachedSpecialty.isNotEmpty) {
            _specialtyController.text = cachedSpecialty;
          }
          if (cachedSocial != null && cachedSocial.isNotEmpty) {
            _socialLinkController.text = cachedSocial;
          }
        });
      }
    } catch (_) {}
  }

  void _addProject({
    String title = '',
    String desc = '',
    String url = '',
    String skills = '',
    String image = '',
  }) {
    setState(() {
      _projects.add(
        ProjectInput(
          title: title,
          desc: desc,
          url: url,
          skills: skills,
          image: image.isNotEmpty
              ? image
              : 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?q=80&w=600',
        ),
      );
    });
  }

  void _removeProject(int index) {
    if (_projects.length <= 1) return;
    setState(() {
      _projects[index].dispose();
      _projects.removeAt(index);
    });
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _photoUrlController.dispose();
    _gitLinkController.dispose();
    _specialtyController.dispose();
    _socialLinkController.dispose();
    for (var project in _projects) {
      project.dispose();
    }
    super.dispose();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    // Validate projects
    bool projectsValid = true;
    for (var p in _projects) {
      if (p.titleController.text.trim().isEmpty) {
        projectsValid = false;
      }
    }

    if (!projectsValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in titles for all projects'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final roleName = _role.name;
    final name = _nameController.text.trim();
    final title = _titleController.text.trim();
    final bio = _bioController.text.trim();
    final skills = _skillsController.text.trim();
    final photoUrl = _photoUrlController.text.trim();

    // Map projects list to JSON array
    final projectsJson = jsonEncode(_projects.map((p) => p.toJson()).toList());

    // Navigate to Plan Selection (Step 3) carrying parameters
    context.go(
      '${RoutePaths.onboardingPlan}'
      '?role=$roleName'
      '&full_name=${Uri.encodeComponent(name)}'
      '&title=${Uri.encodeComponent(title)}'
      '&bio=${Uri.encodeComponent(bio)}'
      '&skills=${Uri.encodeComponent(skills)}'
      '&avatar_url=${Uri.encodeComponent(photoUrl)}'
      '&accent_color=${Uri.encodeComponent(_selectedColor)}'
      '&layout_template=$_layoutTemplate'
      '&projects=${Uri.encodeComponent(projectsJson)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Color(
      int.parse(_selectedColor.replaceFirst('#', '0xFF')),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          // Aurora background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _auroraController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AuroraPainter(
                    t: _auroraController.value,
                    accentHex: _selectedColor,
                  ),
                );
              },
            ),
          ),

          // Form Content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // Step Indicator & Back Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              context.go(RoutePaths.onboardingRole),
                        ),
                        const Expanded(
                          child: Text(
                            'Step 2 of 6',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  // Step Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Container(
                      height: 4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 2 / 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Details',
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Customize details based on your specialization as a ${_role.label}.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Form Card
                              _buildGlassFormCard(activeColor),
                              const SizedBox(height: AppSpacing.xl),

                              // Save & Continue button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [
                                        activeColor,
                                        activeColor.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: activeColor.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _onContinue,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Save & Continue',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassFormCard(Color activeColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1.0,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'PROFILE DETAILS',
                  Icons.person_rounded,
                  activeColor,
                ),
                const SizedBox(height: 12),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(
                    'Full Name',
                    Icons.person_outline,
                    activeColor,
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),

                // Professional Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(
                    'Professional Title',
                    Icons.work_outline,
                    activeColor,
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter your title' : null,
                ),
                const SizedBox(height: 12),

                // Bio
                TextFormField(
                  controller: _bioController,
                  maxLines: 2,
                  maxLength: 250,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration:
                      _inputDecoration(
                        'Short Bio',
                        Icons.chat_bubble_outline,
                        activeColor,
                      ).copyWith(
                        alignLabelWithHint: true,
                        counterStyle: const TextStyle(
                          color: AppColors.textMuted,
                        ),
                      ),
                  validator: (v) => v!.trim().isEmpty ? 'Write a bio' : null,
                ),
                const SizedBox(height: 8),

                // Skills
                TextFormField(
                  controller: _skillsController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration:
                      _inputDecoration(
                        'Skills (comma separated)',
                        Icons.star_outline_rounded,
                        activeColor,
                      ).copyWith(
                        hintText: 'e.g. Flutter, Laravel, Design',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'List your skills' : null,
                ),
                const SizedBox(height: 12),

                // Photo URL
                TextFormField(
                  controller: _photoUrlController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration(
                    'About Photo URL',
                    Icons.image_outlined,
                    activeColor,
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Enter avatar URL' : null,
                ),
                const SizedBox(height: 12),

                // Dynamic Specialization Fields
                _buildRoleSpecificFields(activeColor),
                const SizedBox(height: 24),

                _buildSectionHeader(
                  'THEME COLOR',
                  Icons.palette_rounded,
                  activeColor,
                ),
                const SizedBox(height: 12),

                // Color picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _colorOptions.map((c) {
                    final hex = c['hex']!;
                    final isSelected = _selectedColor == hex;
                    final color = Color(
                      int.parse(hex.replaceFirst('#', '0xFF')),
                    );

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // PROJECTS SECTION
                Row(
                  children: [
                    _buildSectionHeader(
                      'PROJECTS / WORK ENTRIES',
                      Icons.folder_open_rounded,
                      activeColor,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _addProject(),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text(
                        'Add Project',
                        style: TextStyle(color: activeColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Projects Input Cards
                ..._projects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final project = entry.value;

                  return _buildProjectCard(project, index, activeColor);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificFields(Color activeColor) {
    if (_role == ProfessionalRole.developer) {
      return TextFormField(
        controller: _gitLinkController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: _inputDecoration(
          'GitHub Profile Link',
          Icons.code_rounded,
          activeColor,
        ),
      );
    } else if (_role == ProfessionalRole.photographer) {
      return Column(
        children: [
          TextFormField(
            controller: _specialtyController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              'Shooting Specialties (Portrait, Landscape...)',
              Icons.camera_alt_outlined,
              activeColor,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _socialLinkController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              'Instagram Link',
              Icons.photo_camera_back_outlined,
              activeColor,
            ),
          ),
        ],
      );
    } else if (_role == ProfessionalRole.writer) {
      return Column(
        children: [
          TextFormField(
            controller: _specialtyController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              'Writing Genres (Fiction, Tech...)',
              Icons.menu_book_outlined,
              activeColor,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _socialLinkController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              'Substack Link',
              Icons.rss_feed_rounded,
              activeColor,
            ),
          ),
        ],
      );
    } else if (_role == ProfessionalRole.videographer) {
      return Column(
        children: [
          TextFormField(
            controller: _specialtyController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              'Shooting Gear list (e.g. Sony A7SIII)',
              Icons.video_camera_back_outlined,
              activeColor,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _socialLinkController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDecoration(
              'YouTube Channel Link',
              Icons.play_circle_fill_rounded,
              activeColor,
            ),
          ),
        ],
      );
    } else {
      return TextFormField(
        controller: _socialLinkController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: _inputDecoration(
          'LinkedIn Link',
          Icons.link_rounded,
          activeColor,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String label, IconData icon, Color activeColor) {
    return Row(
      children: [
        Icon(icon, color: activeColor, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(ProjectInput project, int index, Color activeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Project #${index + 1}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (index > 0)
                GestureDetector(
                  onTap: () => _removeProject(index),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          TextFormField(
            controller: project.titleController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration(
              'Project Title',
              Icons.folder_outlined,
              activeColor,
            ),
            validator: (v) => v!.trim().isEmpty ? 'Enter project title' : null,
          ),
          const SizedBox(height: 8),

          // Description
          TextFormField(
            controller: project.descController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration(
              'Description',
              Icons.description_outlined,
              activeColor,
            ),
          ),
          const SizedBox(height: 8),

          // Link URL
          TextFormField(
            controller: project.urlController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration(
              'Project URL / Link',
              Icons.link_rounded,
              activeColor,
            ),
          ),
          const SizedBox(height: 8),

          // Skills used
          TextFormField(
            controller: project.skillsController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration(
              'Tags / Technologies (e.g. Vue)',
              Icons.star_border_rounded,
              activeColor,
            ),
          ),
          const SizedBox(height: 8),

          // Image URL
          TextFormField(
            controller: project.imageController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: _inputDecoration(
              'Project Image URL',
              Icons.photo_outlined,
              activeColor,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    Color activeColor,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.textMuted.withValues(alpha: 0.8),
        fontSize: 12,
      ),
      prefixIcon: Icon(icon, color: activeColor, size: 18),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: activeColor, width: 1.2),
      ),
    );
  }
}

// ─── Custom Painter for Ambient Glow ────────────────────────────────────

class _AuroraPainter extends CustomPainter {
  final double t;
  final String accentHex;

  _AuroraPainter({required this.t, required this.accentHex});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tau = math.pi * 2;

    // Base background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF050816),
    );

    final accent = Color(int.parse(accentHex.replaceFirst('#', '0xFF')));

    // Moving Orb 1 (Accent)
    _drawOrb(
      canvas,
      Offset(
        w * (0.7 + 0.2 * math.sin(t * tau)),
        h * (0.3 + 0.15 * math.cos(t * tau)),
      ),
      w * 0.75,
      accent,
      0.14,
    );

    // Moving Orb 2 (Complementary Indigo)
    _drawOrb(
      canvas,
      Offset(
        w * (0.25 + 0.2 * math.cos((t + 0.5) * tau)),
        h * (0.75 + 0.15 * math.sin((t + 0.5) * tau)),
      ),
      w * 0.65,
      const Color(0xFF6366F1),
      0.08,
    );
  }

  void _drawOrb(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.accentHex != accentHex;
}
