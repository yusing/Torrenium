import 'package:flutter/material.dart';
import 'package:torrenium/pages/main_page.dart';

class DesktopView extends StatelessWidget {
  const DesktopView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainPage();
  }
}

class MobileView extends DesktopView {
  const MobileView({super.key});

  // @override
  // Widget build(BuildContext context) {
  //   return Container();
  // }
}
