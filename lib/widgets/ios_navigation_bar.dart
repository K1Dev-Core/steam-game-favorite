import 'package:flutter/cupertino.dart';

class IosNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const IosNavigationBar({
    super.key,
    this.title,
    this.actions,
    this.toolbarHeight = 44,
  });
  final Widget? title;
  final List<Widget>? actions;
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) => CupertinoNavigationBar(
    transitionBetweenRoutes: false,
    backgroundColor: const Color(0xFFF2F2F7),
    border: null,
    middle: title,
    trailing: actions == null
        ? null
        : Row(mainAxisSize: MainAxisSize.min, children: actions!),
  );
}
