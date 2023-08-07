extension TitleExtractor on String {
  String
      get cleanTitle => // remove things in brackets including brackets: () [] {} 【】 ★★
          replaceAll(RegExp(r'(\(|\[|\{|\【)[^\(\[\{【★]*(\)|\]|\}|\】)'), ' ')
              // remove all non english characters
              .replaceAll(RegExp(r'[^a-zA-Z]'), ' ')
              // remove all extra spaces
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
}
