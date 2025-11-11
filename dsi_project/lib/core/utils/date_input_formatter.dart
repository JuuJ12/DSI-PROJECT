import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    final numbersOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    if (numbersOnly.length > 8) {
      return oldValue;
    }

    String formatted = '';

    for (int i = 0; i < numbersOnly.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += numbersOnly[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
