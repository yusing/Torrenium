import 'package:flutter/material.dart';

const gradientDecoration = BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        tileMode: TileMode.decal,
        colors: [
      Color.fromARGB(16, 127, 127, 127),
      Color.fromARGB(16, 0, 0, 0),
    ]));
