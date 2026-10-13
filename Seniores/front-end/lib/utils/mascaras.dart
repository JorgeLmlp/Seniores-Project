import 'package:flutter/services.dart';

//Mascara cpf
class Cpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue valorAntigo,
    TextEditingValue valorNovo,
  ) {
    var texto = valorNovo.text.replaceAll(RegExp(r'\D'), '');

    //formato: 000.000.000-00
    if (texto.length > 11) {
      texto = texto.substring(0, 11);
    }

    if (texto.length > 9) {
      texto =
          '${texto.substring(0, 3)}.${texto.substring(3, 6)}.${texto.substring(6, 9)}-${texto.substring(9)}';
    } else if (texto.length > 6) {
      texto =
          '${texto.substring(0, 3)}.${texto.substring(3, 6)}.${texto.substring(6)}';
    } else if (texto.length > 3) {
      texto = '${texto.substring(0, 3)}.${texto.substring(3)}';
    }

    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(
        offset: texto.length,
      ),
    );
  }
}

// Máscara CEP: 00000-000
class Cep extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var numeros = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (numeros.length > 8) {
      numeros = numeros.substring(0, 8);
    }

    if (numeros.length > 5) {
      numeros = '${numeros.substring(0, 5)}-${numeros.substring(5)}';
    }

    return TextEditingValue(
      text: numeros,
      selection: TextSelection.collapsed(
        offset: numeros.length,
      ),
    );
  }
}

//Mascara telefone
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final text =
        digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;
    final formatted = StringBuffer();
    final length = text.length;

    if (length > 0) {
      formatted.write('(${text.substring(0, length >= 2 ? 2 : length)}');
    }

    if (length > 2) {
      formatted.write(') ');

      if (length <= 10) {
        //formato telefone fixo: (00) 0000-0000
        formatted.write(text.substring(2, length >= 6 ? 6 : length));
        if (length > 6) {
          formatted.write('-${text.substring(6)}');
        }
      } else {
        //formato celular: (00) 00000-0000
        formatted.write(text.substring(2, 7));
        formatted.write('-${text.substring(7)}');
      }
    }

    final textoFormatado = formatted.toString();

    return TextEditingValue(
      text: textoFormatado,
      selection: TextSelection.collapsed(offset: textoFormatado.length),
    );
  }
}
