import 'package:flutter/services.dart';

abstract final class PhoneNumberFormatter {
  static final RegExp _nonDigits = RegExp(r'\D');

  static String digitsOnly(String value) => value.replaceAll(_nonDigits, '');

  static String normalize(String value) {
    var digits = digitsOnly(value);
    if (digits.length > 11 && digits.startsWith('55')) {
      digits = digits.substring(2);
    }
    return digits.length <= 11 ? digits : digits.substring(0, 11);
  }

  static String format(String value) => formatDigits(normalize(value));

  static String formatDigits(String digits) {
    if (digits.isEmpty) return '';
    if (digits.length == 1) return '($digits';

    final areaCode = digits.substring(0, 2);
    if (digits.length == 2) return '($areaCode) ';

    final subscriber = digits.substring(2);
    final prefixLength = subscriber.startsWith('9') ? 5 : 4;
    if (subscriber.length <= prefixLength) {
      return '($areaCode) $subscriber';
    }

    return '($areaCode) ${subscriber.substring(0, prefixLength)}-'
        '${subscriber.substring(prefixLength)}';
  }
}

class BrazilianPhoneInputFormatter extends TextInputFormatter {
  const BrazilianPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = PhoneNumberFormatter.normalize(oldValue.text);
    var newDigits = PhoneNumberFormatter.normalize(newValue.text);
    var digitsBeforeCursor = _digitsBeforeCursor(newValue);

    final removedOnlyFormatting = newValue.text.length < oldValue.text.length &&
        newDigits == oldDigits &&
        newDigits.isNotEmpty;
    if (removedOnlyFormatting) {
      final removeAt = digitsBeforeCursor > 0 ? digitsBeforeCursor - 1 : 0;
      newDigits =
          newDigits.substring(0, removeAt) + newDigits.substring(removeAt + 1);
      digitsBeforeCursor = removeAt;
    }

    final formatted = PhoneNumberFormatter.formatDigits(newDigits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _selectionOffset(formatted, digitsBeforeCursor),
      ),
    );
  }

  int _digitsBeforeCursor(TextEditingValue value) {
    final cursor = value.selection.extentOffset.clamp(0, value.text.length);
    return PhoneNumberFormatter.digitsOnly(value.text.substring(0, cursor))
        .length
        .clamp(0, 11);
  }

  int _selectionOffset(String formatted, int digitsBeforeCursor) {
    if (formatted.isEmpty) return 0;
    if (digitsBeforeCursor <= 0) return 1;
    final totalDigits = PhoneNumberFormatter.digitsOnly(formatted).length;
    if (digitsBeforeCursor >= totalDigits) return formatted.length;

    var seenDigits = 0;
    for (var index = 0; index < formatted.length; index++) {
      if (RegExp(r'\d').hasMatch(formatted[index])) {
        seenDigits++;
        if (seenDigits == digitsBeforeCursor) return index + 1;
      }
    }
    return formatted.length;
  }
}
