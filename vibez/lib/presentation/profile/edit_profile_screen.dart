import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/provider/user_provider.dart';
import 'package:vibez/data/repositories/user_repository.dart';
import 'package:vibez/core/utils/app_snackbar.dart';

extension ColorX on Color {
  String toHex({bool leadingHashSign = true}) {
    return toARGB32().toRadixString(16).padLeft(8, '0');
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _bioController = TextEditingController();
  final _bioFocusNode = FocusNode();

  Timer? _debounceTimer;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _originalUsername;

  Color _selectedColor = const Color(0xFF8B5CF6);
  File? _imageFile;
  String? _existingProfileUrl;
  bool _isLoading = false;

  final List<Color> _colors = const [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E3C),
    Color(0xFFFFD166),
    Color(0xFF06D6A0),
    Color(0xFF00D4FF),
    Color(0xFF3A86FF),
    Color(0xFF8338EC),
    Color(0xFFFF006E),
  ];

  final List<String> _genres = const [
    "Bollywood",
    "Punjabi",
    "Hip-Hop",
    "Indie",
    "Lo-fi",
    "R&B",
    "House",
    "Techno",
    "EDM",
    "Afrobeats",
    "K-Pop",
    "Trap",
    "Synthwave",
    "Deep House",
    "Ambient",
    "Ghazal",
    "Rock",
    "Pop",
  ];

  final List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProvider);
    _originalUsername = profile?.username ?? '';
    _usernameController = TextEditingController(text: _originalUsername);
    _usernameController.addListener(_onUsernameChanged);
    _bioController.text = profile?.bio ?? '';
    _bioController.addListener(_onBioChanged);

    final profileUrl = profile?.profileUrl;
    if (profileUrl != null && profileUrl.isNotEmpty) {
      if (profileUrl.startsWith('default://')) {
        final hex = profileUrl.replaceFirst('default://', '');
        try {
          _selectedColor = Color(int.parse(hex, radix: 16));
        } catch (_) {
          _selectedColor = const Color(0xFF8B5CF6);
        }
      } else {
        _existingProfileUrl = profileUrl;
      }
    } else {
      _selectedColor = const Color(0xFF8B5CF6);
    }

    if (profile?.tags != null) {
      _selectedGenres.addAll(profile!.tags!);
    }
  }

  void _onUsernameChanged() {
    final text = _usernameController.text.trim();
    _debounceTimer?.cancel();

    if (text == _originalUsername) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
      });
      return;
    }

    if (text.isEmpty || text.length < 3 || text.length > 16) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
      });
      return;
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
    if (!usernameRegex.hasMatch(text)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      try {
        final available = await UserRepository.instance.checkUsername(text);
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = available;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = null;
        });
      }
    });
  }

  void _onBioChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _usernameController.dispose();
    _bioController.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
      _imageFile = null;
      _existingProfileUrl = null;
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        if (_selectedGenres.length < 5) {
          _selectedGenres.add(genre);
        } else {
          AppSnackbar.show(
            message: "You can select up to 5 favorite genres.",
            type: AppSnackType.info,
          );
        }
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
          _existingProfileUrl =
              null; // Clear existing remote/local url since we have new file
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.s2),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                "Profile photo",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: Text(
                  "Take photo",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(color: AppColors.hairlineLight, height: 1),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.secondary,
                ),
                title: Text(
                  "Choose from library",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imageFile != null || _existingProfileUrl != null) ...[
                const Divider(color: AppColors.hairlineLight, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    "Remove current photo",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFile = null;
                      _existingProfileUrl = null;
                    });
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.s4),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    final Map<String, dynamic> data = {
      'username': username,
      'bio': bio,
      'tags': _selectedGenres,
    };

    if (_imageFile != null) {
      data['profileUrl'] = _imageFile!.path;
    } else if (_existingProfileUrl != null) {
      data['profileUrl'] = _existingProfileUrl;
    } else {
      data['profileUrl'] = "default://${_selectedColor.toHex()}";
    }

    final success = await ref.read(userProvider.notifier).updateProfile(data);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      AppSnackbar.show(
        message: "Profile updated successfully!",
        type: AppSnackType.success,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      AppSnackbar.show(
        message: "Failed to update profile. Username may already be taken.",
        type: AppSnackType.error,
      );
    }
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2, top: AppSpacing.s4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.text2,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.text3, fontSize: 15),
      filled: true,
      fillColor: AppColors.cardAlt,
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBorderRadius,
        borderSide: const BorderSide(color: AppColors.hairlineLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBorderRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBorderRadius,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdBorderRadius,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final String avatarLetter = (user?.name.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : 'A';
    final hasImage = _imageFile != null || _existingProfileUrl != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Edit profile",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.s2),

                Center(
                  child: GestureDetector(
                    onTap: _showImageSourceBottomSheet,
                    child: Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          color: _selectedColor,
                          child: _imageFile != null
                              ? Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          avatarLetter,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                )
                              : (_existingProfileUrl != null
                                    ? (_existingProfileUrl!.startsWith(
                                                'http://',
                                              ) ||
                                              _existingProfileUrl!.startsWith(
                                                'https://',
                                              )
                                          ? Image.network(
                                              _existingProfileUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Center(
                                                    child: Text(
                                                      avatarLetter,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 54,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                            )
                                          : Image.file(
                                              File(_existingProfileUrl!),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Center(
                                                    child: Text(
                                                      avatarLetter,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 54,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                            ))
                                    : Center(
                                        child: Text(
                                          avatarLetter,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 54,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _showImageSourceBottomSheet,
                    icon: Icon(
                      hasImage
                          ? Icons.edit_outlined
                          : Icons.camera_alt_outlined,
                      size: 16,
                    ),
                    label: Text(hasImage ? "Change photo" : "Add photo"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.card, width: 1.5),
                      backgroundColor: AppColors.surface,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.s4),

                Row(
                  children: [
                    Text(
                      "or pick a color",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.text2),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colors.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: AppSpacing.s2),
                          itemBuilder: (context, index) {
                            final color = _colors[index];
                            final isSelected =
                                _selectedColor == color && !hasImage;
                            return GestureDetector(
                              onTap: () => _selectColor(color),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s5),

                _buildSectionLabel("Username"),
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: _fieldDecoration("Username"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    final text = value.trim();
                    if (text.length < 3) return 'At least 3 characters';
                    if (text.length > 16) return 'At most 16 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(text)) {
                      return 'Only letters, numbers, underscores, and dots';
                    }
                    if (_isUsernameAvailable == false) {
                      return 'Username is already taken';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.s1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "3-16 characters · letters, numbers, underscores",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.text3,
                      ),
                    ),
                    if (_isCheckingUsername)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    else if (_isUsernameAvailable == true)
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16)
                    else if (_isUsernameAvailable == false)
                      const Icon(Icons.cancel_rounded, color: Colors.red, size: 16),
                  ],
                ),

                const SizedBox(height: AppSpacing.s2),

                Row(
                  children: [
                    Text(
                      "Bio",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      " · optional",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.text3),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s2),
                TextFormField(
                  controller: _bioController,
                  focusNode: _bioFocusNode,
                  maxLength: 80,
                  maxLines: 3,
                  minLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        "e.g. late-night selector · mostly house & hyperpop",
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.text3,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: AppColors.cardAlt,
                    counterText: "",
                    contentPadding: const EdgeInsets.all(AppSpacing.s3),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdBorderRadius,
                      borderSide: const BorderSide(
                        color: AppColors.hairlineDark,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdBorderRadius,
                      borderSide: const BorderSide(
                        color: AppColors.hairlineDark,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdBorderRadius,
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${_bioController.text.length}/80",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.text3),
                  ),
                ),

                const SizedBox(height: AppSpacing.s3),

                Row(
                  children: [
                    Text(
                      "Favorite genres",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      " · ${_selectedGenres.length}/5",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.text3),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _genres.map((genre) {
                    final isSelected = _selectedGenres.contains(genre);
                    return GestureDetector(
                      onTap: () => _toggleGenre(genre),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.hairlineDark,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.text
                                : AppColors.text2,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.s8),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _isCheckingUsername) ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.done, color: Colors.white, size: 20),
                    label: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save changes",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillBorderRadius,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
