import 'package:flutter/material.dart';

enum ResponsiveSize { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, ResponsiveSize size) builder;
  static ResponsiveSize sizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 1100
        ? ResponsiveSize.desktop
        : width >= 700
        ? ResponsiveSize.tablet
        : ResponsiveSize.mobile;
  }

  static bool isDesktop(BuildContext context) =>
      sizeOf(context) == ResponsiveSize.desktop;
  @override
  Widget build(BuildContext context) => builder(context, sizeOf(context));
}
