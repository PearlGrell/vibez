import 'package:flutter/material.dart';
import 'package:vibez/core/theme/colors.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  const AppSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Rooms, DJs, songs...',
          hintStyle: TextStyle(color: AppColors.text3, fontSize: 15),

          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(Icons.search_rounded, color: AppColors.text3, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 46),

          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: AppColors.text3,
                  size: 20,
                ),
                onPressed: () {
                  controller.clear();
                  FocusScope.of(context).unfocus();
                },
              );
            },
          ),

          filled: true,
          fillColor: const Color(0xFF111111),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFF252525), width: 1),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFF252525), width: 1),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .4),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
