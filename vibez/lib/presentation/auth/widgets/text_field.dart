import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibez/core/theme/colors.dart';
import 'package:vibez/core/theme/radius.dart';
import 'package:vibez/core/theme/spacing.dart';
import 'package:vibez/core/theme/typography.dart';

class EditText extends StatefulWidget {
  const EditText({
    super.key,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.password = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
  });

  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool password;
  final bool enabled;
  final bool autofocus;
  final int? maxLength;

  @override
  State<EditText> createState() => _EditTextState();
}

class _EditTextState extends State<EditText> {
  late bool _obscureText;
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.password;

    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _hasFocus) {
      setState(() => _hasFocus = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelColor = _hasFocus ? theme.primaryColor : AppColors.text2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.s3,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.bodySmall?.copyWith(color: labelColor),
        ),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          obscureText: _obscureText,
          maxLength: widget.maxLength,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            isDense: true,
            counterText: '', 
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.text2)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s2,
              vertical: AppSpacing.s4,
            ),
            hintText: widget.hintText,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.text2,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: widget.password ? _buildPasswordToggle(theme) : null,
            suffixIconConstraints: const BoxConstraints(minHeight: 48),
            border: _border(AppColors.text2, 0.5),
            enabledBorder: _border(AppColors.text2, 0.5),
            focusedBorder: _border(theme.primaryColor, 1),
            disabledBorder: _border(AppColors.text2.withValues(alpha: 0.4), 0.5),
            errorBorder: _border(theme.colorScheme.error, 0.5),
            focusedErrorBorder: _border(theme.colorScheme.error, 1),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordToggle(ThemeData theme) {
    return Semantics(
      button: true,
      label: _obscureText ? 'Show password' : 'Hide password',
      child: InkWell(
        onTap: () => setState(() => _obscureText = !_obscureText),
        borderRadius: AppRadius.mdBorderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            widthFactor: 1,
            child: Text(
              _obscureText ? 'SHOW' : 'HIDE',
              style: theme.textTheme.mono().copyWith(color: AppColors.text2),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: AppRadius.mdBorderRadius,
      borderSide: BorderSide(width: width, color: color),
    );
  }
}