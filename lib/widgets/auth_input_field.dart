// AuthInputField - Reusable text input for authentication screens with optional password toggle

import 'package:flutter/material.dart';

class AuthInputField extends StatefulWidget {
  final String hint;
  final bool isPassword;
  final Color fieldBg;
  final Color grey900;
  final Color grey300;

  const AuthInputField({
    super.key,
    required this.hint,
    required this.fieldBg,
    required this.grey900,
    required this.grey300,
    this.isPassword = false,
  });

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: widget.fieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        textAlign: TextAlign.right,
        textAlignVertical: TextAlignVertical.center,
        obscureText: widget.isPassword ? _obscure : false,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: widget.grey900,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          hintText: widget.hint,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.grey300,
          ),
          // Visibility toggle positioned on leading edge for RTL layout
          suffixIcon: widget.isPassword
              ? IconButton(
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: widget.grey900,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ),
    );
  }
}