import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // The visual styling is driven by AppTheme.inputDecorationTheme
    return SizedBox(
      height: 52, // From guidelines
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
