import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/utils/app_snackbar.dart';
import 'package:vibez/data/models/room.dart';
import 'package:vibez/data/repositories/room_repository.dart';
import 'package:vibez/presentation/common/album_art_cover.dart';
import 'package:vibez/presentation/common/equalizer_bars.dart';
import 'package:vibez/data/provider/user_provider.dart';

class AddRoomScreen extends ConsumerStatefulWidget {
  final Room? room;
  const AddRoomScreen({super.key, this.room});

  @override
  ConsumerState<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends ConsumerState<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isPrivate = true;
  bool _isLoading = false;

  final List<String> _availableTags = [
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

  final List<String> _selectedTags = [];

  bool get _isEditing => widget.room != null;

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _nameController = TextEditingController(text: room?.name ?? '');
    _descriptionController = TextEditingController(text: room?.description ?? '');
    if (room != null) {
      _isPrivate = room.private;
      _selectedTags.addAll(room.tags);
    } else {
      _selectedTags.add('Indie');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final tags = _selectedTags;

    final result = _isEditing
        ? await RoomRepository.instance.updateRoom(
            id: widget.room!.id,
            name: name,
            description: description,
            tags: tags,
            private: _isPrivate,
          )
        : await RoomRepository.instance.createRoom(
            name: name,
            description: description,
            tags: tags,
            private: _isPrivate,
          );

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      ref.read(userProvider.notifier).fetchMyRooms();
      AppSnackbar.show(
        message: _isEditing
            ? "Room updated successfully!"
            : "Room '$name' created successfully!",
        type: AppSnackType.success,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Edit room" : "Create room",
          style: const TextStyle(
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

                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, value, _) {
                    final nameText = value.text.trim();
                    return Center(
                      child: Column(
                        children: [
                          AlbumArtCover(
                            seed: nameText.isNotEmpty ? nameText : 'Room',
                            size: 160,
                            radius: AppRadius.xl,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 16,
                                  bottom: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          SizedBox(
                                            height: 14,
                                            child: EqualizerBars(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        nameText.isNotEmpty
                                            ? nameText
                                            : 'Room name',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Cover auto-generates from your room name",
                            style: TextStyle(
                              color: AppColors.text3,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.s4),

                _buildSectionLabel("Room name"),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: _fieldDecoration("e.g. Late Night Vibes"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.s2),

                _buildSectionLabel("Description · optional"),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: AppColors.text),
                  decoration: _fieldDecoration("What's the vibe?"),
                  maxLines: 3,
                ),

                const SizedBox(height: AppSpacing.s4),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4,
                    vertical: AppSpacing.s3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: AppRadius.mdBorderRadius,
                    border: Border.all(color: AppColors.hairlineLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.public,
                          color: Color(0xFF22C55E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Public",
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Anyone can discover & join",
                              style: TextStyle(
                                color: AppColors.text3,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: !_isPrivate,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _isPrivate = !val;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s4),

                _buildSectionLabel("Genre tags · ${_selectedTags.length}/3"),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTags.remove(tag);
                          } else {
                            if (_selectedTags.length < 3) {
                              _selectedTags.add(tag);
                            } else {
                              AppSnackbar.show(
                                message: "You can select up to 3 tags.",
                                type: AppSnackType.info,
                              );
                            }
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: AppRadius.pillBorderRadius,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.hairlineLight,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.text,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
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
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditing ? "Save changes" : "Create room",
                            style: const TextStyle(
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