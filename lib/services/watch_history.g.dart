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
