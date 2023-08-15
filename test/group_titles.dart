import 'dart:convert';

import 'package:torrenium/utils/fetch_rss.dart';
import 'package:torrenium/utils/rss_providers.dart';
import 'package:http/http.dart' as http;
import 'package:torrenium/utils/string.dart';

Map<String, List<int>> groupBySimilarity(List<String> titles) {
  Map<String, List<int>> groupedTitles = {};
  Map<String, int> episodeIndexMap = {};
  Map<String, List<int>> previousNumbersMap = {};
  List<String> ungroupedTitles = [];

  for (var title in titles) {
    title = title
        .removeDelimiters('()[]{}【】★.-_')
        .replaceAll(RegExp(r'(1080|720)\s?p', caseSensitive: false), '')
        .replaceAll(
            RegExp(
                r'(HEVC|AAC|AVC|8bit|10bit|MKV|MP4|MP3|WEBRIP|BAHA|TVB|WEBDL|WEB-DL|招募.+)',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Extract all numbers from the title
    var numbers = RegExp(r'\d+')
        .allMatches(title)
        .map((m) => int.parse(m.group(0)!))
        .toList();

    if (numbers.isEmpty) {
      ungroupedTitles.add(title);
      continue;
    }

    // Remove all numbers from the title
    var titleWithoutNumbers = title.replaceAll(RegExp(r'\d+'), '');
    // Check if this title is similar to any of the existing groups
    var foundGroup = false;
    for (var group in groupedTitles.keys) {
      // If the title and the group are the same after removing numbers, add the episode number to the group
      if (titleWithoutNumbers == group) {
        var episodeIndex = episodeIndexMap[group];
        if (episodeIndex != null && episodeIndex < numbers.length) {
          groupedTitles[group]!.add(numbers[episodeIndex]);
        }
        foundGroup = true;
        break;
      }
    }

    // If the title was not similar to any existing group, create a new group for it
    if (!foundGroup) {
      var previousNumbers = previousNumbersMap[titleWithoutNumbers];
      var episodeIndex = 0;
      if (previousNumbers != null) {
        for (var i = 0; i < numbers.length && i < previousNumbers.length; i++) {
          if (numbers[i] != previousNumbers[i]) {
            episodeIndex = i;
            break;
          }
        }
        episodeIndexMap[titleWithoutNumbers] = episodeIndex;
        groupedTitles[titleWithoutNumbers] = [numbers[episodeIndex]];
      }
    }

    // Store the list of numbers for the next title in the same group
    previousNumbersMap[titleWithoutNumbers] = numbers;
  }
  print('${ungroupedTitles.length} ungrouped titles:');
  return groupedTitles;
}

Future<void> main() async {
  final url = kRssProviders.first.searchUrl();
  final body =
      await http.get(Uri.parse(url)).then((res) => utf8.decode(res.bodyBytes));
  final items = parseRSSForItems(kRssProviders.first, body);
  final titles = items.map((item) => item.name).toList(growable: false);
  final groupedTitles = groupBySimilarity(titles);
  final jsonStr = const JsonEncoder.withIndent('  ').convert(groupedTitles);
  print(jsonStr);
}
