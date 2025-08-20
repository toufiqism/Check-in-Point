import 'package:flutter/material.dart';

Future<void> showMessageDialog({
  required BuildContext context,
  required String title,
  required String message,
  String okText = 'OK',
}) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(okText),
          ),
        ],
      );
    },
  );
}


