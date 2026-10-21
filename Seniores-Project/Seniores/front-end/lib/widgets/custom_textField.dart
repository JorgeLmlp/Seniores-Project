import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CampoTexto extends StatefulWidget {
  final String hintText;
  final bool senha;
  final Icon? prefixIcon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CampoTexto({
    super.key,
    required this.hintText,
    this.senha = false,
    this.prefixIcon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  bool mostrarSenha = false;
  bool temTexto = false;

  @override
  void initState() {
    super.initState();

    temTexto = widget.controller?.text.isNotEmpty ?? false;
    widget.controller?.addListener(_atualizarTexto);
  }

  void _atualizarTexto() {
    if (mounted)
      setState(() => temTexto = widget.controller?.text.isNotEmpty ?? false);
  }

  @override
  void didUpdateWidget(covariant CampoTexto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_atualizarTexto);
      widget.controller?.addListener(_atualizarTexto);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_atualizarTexto);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.senha && !mostrarSenha,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.senha && temTexto
            ? IconButton(
                icon: Icon(
                  mostrarSenha ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    mostrarSenha = !mostrarSenha;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class CampoDropdown extends StatelessWidget {
  final String hintText;
  final String? valor;
  final List<String> itens;
  final Icon? prefixIcon;
  final ValueChanged<String?> onChanged;

  const CampoDropdown({
    super.key,
    required this.hintText,
    required this.valor,
    required this.itens,
    required this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: valor,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
      items: itens.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
