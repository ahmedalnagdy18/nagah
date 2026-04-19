import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

double appHight(BuildContext context, double h) {
  return MediaQuery.of(context).size.height * h;
}

double appWidth(BuildContext context, double w) {
  return MediaQuery.of(context).size.width * w;
}

// Prevent spaces at the start of the text
class PreventStartingSpaceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // Prevent starting with a space by trimming only the beginning
    if (newText.startsWith(' ')) {
      newText = newText.trimLeft();
    }

    // Replace multiple spaces with a single space throughout the text.
    newText = newText.replaceAll(RegExp(r'\s{2,}'), ' ');
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

TextInputFormatter noSpaceFormatter() {
  return TextInputFormatter.withFunction(
    (oldValue, newValue) {
      if (newValue.text.startsWith(' ')) {
        final newText = newValue.text.trimLeft();
        return newValue.copyWith(
          text: newText,
          selection: TextSelection.fromPosition(
            TextPosition(offset: newText.length),
          ),
        );
      }
      return newValue;
    },
  );
} //  noSpaceFormatter(),   to call it

// or

//  inputFormatters: [
//              FilteringTextInputFormatter.deny(RegExp(r'\s')),
//                           ],

void showToastMessage({required String message}) {
  Fluttertoast.showToast(
    msg: message,
    backgroundColor: Colors.green,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 1,
    textColor: Colors.white,
    fontSize: 14.0.sp,
  );
}
// showToastMessage(message: "Added successfully");   to call it

void showErrorToastMessage({required String message}) {
  Fluttertoast.showToast(
    msg: message,
    backgroundColor: Colors.red,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 2,
    textColor: Colors.white,
    fontSize: 14.0.sp,
  );
}
