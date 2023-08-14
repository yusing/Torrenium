import 'package:flutter/widgets.dart';

const gradientDecoration = BoxDecoration(
    shape: BoxShape.rectangle,
    borderRadius: BorderRadius.all(Radius.circular(10)),
    gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        tileMode: TileMode.decal,
        colors: [
          Color.fromARGB(16, 127, 127, 127),
          Color.fromARGB(16, 0, 0, 0),
        ]));
