// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchHistoryEntry _$WatchHistoryEntryFromJson(Map<String, dynamic> json) =>
    WatchHistoryEntry(
      nameHash: json['nameHash'] as String,
      title: json['title'] as String,
      duration: json['duration'] as int?,
      position: json['position'] as int?,
    );

Map<String, dynamic> _$WatchHistoryEntryToJson(WatchHistoryEntry instance) =>
    <String, dynamic>{
      'nameHash': instance.nameHash,
      'title': instance.title,
      'duration': instance.duration,
      'position': instance.position,
    };

WatchHistories _$WatchHistoriesFromJson(Map<String, dynamic> json) =>
    WatchHistories(
      (json['value'] as List<dynamic>)
          .map((e) => WatchHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WatchHistoriesToJson(WatchHistories instance) =>
    <String, dynamic>{
      'value': instance.value,
    };
