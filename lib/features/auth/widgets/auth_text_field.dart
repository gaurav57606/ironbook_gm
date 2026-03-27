import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: AppTextStyles.tinySize,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword && !_isVisible,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: GoogleFonts.outfit(
              fontSize: (widget.isPassword && !_isVisible) ? 14 : AppTextStyles.bodySize,
              color: AppColors.textPrimary,
              letterSpacing: (widget.isPassword && !_isVisible) ? 3 : 0,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: AppTextStyles.bodySize,
                color: AppColors.textMuted,
                letterSpacing: 0,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      onPressed: () => setState(() => _isVisible = !_isVisible),
                      icon: Icon(
                        _isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              filled: true,
              fillColor: AppColors.bg3,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
          ),
        ],
      ),
    );
  }
}
