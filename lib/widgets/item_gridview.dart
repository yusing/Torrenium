import 'package:flutter/material.dart';
import 'package:torrenium/classes/item.dart';
import 'package:torrenium/style.dart';
import 'package:torrenium/widgets/item_card.dart';

class ItemGridView extends StatelessWidget {
  final ScrollController? controller;
  final List<Item> items;
  const ItemGridView({this.controller, required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
          shrinkWrap: true,
          controller: controller,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: kCoverPhotoWidth,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.7),
          itemCount: items.length,
          itemBuilder: ((_, index) => ItemCard(item: items[index]))),
    );
  }
}
