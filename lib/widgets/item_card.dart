import 'package:flutter/cupertino.dart';

import '../classes/item.dart';
import '../style.dart';
import 'cached_image.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  const ItemCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => item.showDialog(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(0, 0, 0, 0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
                child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedImage(
                  url: item.coverUrl,
                  fallbackGetter: item.coverPhotoFallback,
                  width: kCoverPhotoWidth),
            )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                style: kItemTitleTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
