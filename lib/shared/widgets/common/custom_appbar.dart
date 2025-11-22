import 'package:flutter/material.dart';
import 'package:hajzy/core/theme/theme_extensions.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true, String? subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(color: context.textPrimary),
      ),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      backgroundColor: context.surface,
      elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
