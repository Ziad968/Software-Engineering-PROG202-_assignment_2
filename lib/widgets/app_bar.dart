import 'package:flutter/material.dart';

/// Shared AppBar builder used across primary screens.
PreferredSizeWidget buildAppBar({
  required String title,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    actions: actions,
    bottom: bottom,
  );
}