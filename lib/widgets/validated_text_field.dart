import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget TextFormField mejorado con validación integrada y feedback visual
class ValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffixWidget;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final bool obscureText;
  final String? helperText;
  final bool isRequired;

  const ValidatedTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixWidget,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.onChanged,
    this.obscureText = false,
    this.helperText,
    this.isRequired = false,
  });

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late FocusNode _focusNode;
  String? _errorMessage;
  bool _hasInteracted = false; // Mostrar error solo después de interacción

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    widget.controller.addListener(_validateOnChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_validateOnChange);
    super.dispose();
  }

  void _validateOnChange() {
    if (_hasInteracted) {
      _validateField();
    }
  }

  void _validateField() {
    setState(() {
      if (widget.validator != null) {
        _errorMessage = widget.validator!(widget.controller.text);
      } else {
        _errorMessage = null;
      }
    });
  }

  void _onFieldTapped() {
    setState(() {
      _hasInteracted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label con asterisco rojo si es requerido
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.labelText,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // TextFormField con decoración mejorada
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          obscureText: widget.obscureText,
          inputFormatters: widget.inputFormatters,
          onChanged: (value) {
            _validateOnChange();
            widget.onChanged?.call(value);
          },
          onTap: _onFieldTapped,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon:
                widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, color: Colors.grey[600])
                    : null,
            suffixIcon:
                widget.suffixWidget ??
                (widget.suffixIcon != null
                    ? Icon(widget.suffixIcon, color: Colors.grey[600])
                    : null),
            helperText: widget.helperText,
            errorText: _hasInteracted ? _errorMessage : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _hasInteracted && _errorMessage != null
                        ? Colors.red
                        : const Color(0xFFE6E9F0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _hasInteracted && _errorMessage != null
                        ? Colors.red
                        : const Color(0xFFE6E9F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _hasInteracted && _errorMessage != null
                        ? Colors.red
                        : const Color(0xFF2E1A6F),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor:
                _hasInteracted && _errorMessage != null
                    ? Colors.red.withValues(alpha: 0.05)
                    : const Color(0xFFFAFBFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),

        // Mostrar error con icono si existe
        if (_hasInteracted && _errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
