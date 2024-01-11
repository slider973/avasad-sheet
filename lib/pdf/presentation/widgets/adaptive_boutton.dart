import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AdaptiveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (theme.platform == TargetPlatform.iOS) {
      return CupertinoButton(
       color: theme.primaryColor,
        pressedOpacity: 0.5,
        borderRadius: BorderRadius.circular(50),
        onPressed: onPressed,
        child: Text(text),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      );
    }
  }
}
