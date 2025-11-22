import 'package:flutter/material.dart';

/// Wrapper للصفحات الفرعية لإزالة Scaffold الخاص بها
class PageWrapper extends StatelessWidget {
  final Widget child;

  const PageWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
