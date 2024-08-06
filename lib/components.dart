import 'package:flutter/material.dart';

class CustomTextStyles {
  static const TextStyle customTextStyle = TextStyle(
      fontFamily: 'Lora',
      fontSize: 18,
      color: Colors.black
  );
}

class CustomAppBar {
  static AppBar customAppBar(String title) {
    return AppBar(
      backgroundColor:Color(0xFFe6b67e),
      title: Text(
        title,
        style: customTextStyle,
      ),
      centerTitle: true,
    );
  }

  static  TextStyle customTextStyle = TextStyle(
    fontFamily: 'Lora',
    fontSize: 25,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

class NewCustomTextStyles {
  static const TextStyle newcustomTextStyle = TextStyle(
      fontFamily: 'Lora',
      fontSize: 25,
      color: Colors.white,
    fontWeight: FontWeight.bold,
  );
}

// class CustomButton {
//   static ElevatedButton customButton({
//     required VoidCallback onPressed,
//     required String label,
//     Color backgroundColor = const Color(0xFFE0A45E),
//     Color textColor = Colors.black,
//     EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
//     double fontSize = 30,
//     FontWeight fontWeight = FontWeight.bold,
//     BorderRadiusGeometry borderRadius = const BorderRadius.all(Radius.circular(12)),
//     Icon? icon,
//   }) {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: backgroundColor,
//         padding: padding,
//         textStyle: TextStyle(
//           fontSize: fontSize,
//           fontWeight: fontWeight,
//           color: textColor,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: borderRadius,
//         ),
//         elevation: 5,
//         shadowColor: Colors.black.withOpacity(0.5),
//       ),
//       onPressed: onPressed,
//       child: icon == null
//           ? Text(
//         label,
//         style: TextStyle(color: textColor),
//       )
//           : Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           icon,
//           SizedBox(width: 8),
//           Text(
//             label,
//             style: TextStyle(color: textColor),
//           ),
//         ],
//       ),
//     );
//   }
// }