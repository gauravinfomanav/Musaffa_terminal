
import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class finButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onPressed;

  const finButton({
    Key? key,
    required this.title,
    required this.isSelected,
    required this.onPressed, required BuildContext context,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? CustomColors.GREEN : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : CustomColors.labelGrey,
          fontFamily:Constants.FONT_DEFAULT_NEW,
        ),
      ),
    );
  }
}
