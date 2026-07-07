import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/data/provider/user_provider.dart';

extension ColorX on Color {
  String toHex({bool leadingHashSign = true}) {
    return toARGB32().toRadixString(16).padLeft(8, '0');
  }
}

class CustomizeProfileStep extends ConsumerStatefulWidget {
  final VoidCallback onFinish;

  const CustomizeProfileStep({super.key, required this.onFinish});

  @override
  ConsumerState<CustomizeProfileStep> createState() =>
      _CustomizeProfileStepState();
}

class _CustomizeProfileStepState extends ConsumerState<CustomizeProfileStep> {
  final _bioController = TextEditingController();
  final _bioFocusNode = FocusNode();

  Color _selectedColor = const Color(0xFF22C55E);
  File? _imageFile;
  bool _isSaving = false;

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

  final Set<String> _selectedGenres = {};

  @override
  void initState() {
    super.initState();
    _bioController.addListener(_onBioChanged);
  }

  void _onBioChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _bioController.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        if (_selectedGenres.length < 5) {
          _selectedGenres.add(genre);
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
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
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
              if (_imageFile != null) ...[
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

  Future<void> _handleStartListening() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final Map<String, dynamic> data = {};
      if (_bioController.text.trim().isNotEmpty) {
        data['bio'] = _bioController.text.trim();
      }
      if (_selectedGenres.isNotEmpty) {
        data['tags'] = _selectedGenres.toList();
      }
      if (_imageFile != null) {
        data['profileUrl'] = _imageFile?.path;
      } else {
        data['profileUrl'] = "default://${_selectedColor.toHex()}";
      }

      final success = await ref.read(userProvider.notifier).updateProfile(data);
      if (success && mounted) {
        widget.onFinish();
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final String avatarLetter = (user?.name.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : 'A';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s3),
          Text(
            "Make it yours",
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            "Add a photo and the sounds you love. You can change this anytime.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.text2,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Center(
            child: GestureDetector(
              onTap: _showImageSourceBottomSheet,
              child: Container(
                width: 140,
                height: 140,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.5),
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
                        : Center(
                            child: Text(
                              avatarLetter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Center(
            child: OutlinedButton.icon(
              onPressed: _showImageSourceBottomSheet,
              icon: Icon(
                _imageFile != null
                    ? Icons.edit_outlined
                    : Icons.camera_alt_outlined,
                size: 16,
              ),
              label: Text(_imageFile != null ? "Change photo" : "Add photo"),
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
          const SizedBox(height: AppSpacing.s6),
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
                          _selectedColor == color && _imageFile == null;
                      return GestureDetector(
                        onTap: () => _selectColor(color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.5)
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
          const SizedBox(height: AppSpacing.s6),
          Row(
            children: [
              Text(
                "Bio",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
              hintText: "e.g. late-night selector · mostly house & hyperpop",
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.text3,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: AppColors.surface,
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
          const SizedBox(height: AppSpacing.s5),
          Row(
            children: [
              Text(
                "Favorite genres",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
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
                      color: isSelected ? AppColors.text : AppColors.text2,
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
            height: 56,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _handleStartListening,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
              label: Text(
                "Start listening",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Center(
            child: TextButton(
              onPressed: _isSaving ? null : widget.onFinish,
              style: TextButton.styleFrom(foregroundColor: AppColors.text3),
              child: Text(
                "Skip for now",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s7),
        ],
      ),
    );
  }
}
