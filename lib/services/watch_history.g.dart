// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchHistoryEntry _$WatchHistoryEntryFromJson(Map<String, dynamic> json) =>
    WatchHistoryEntry(
      name: json['name'] as String,
      path: json['path'] as String?,
      audioPath: json['audioPath'] as String?,
      duration: json['duration'] as int?,
      position: json['position'] as int?,
    );

Map<String, dynamic> _$WatchHistoryEntryToJson(WatchHistoryEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'audioPath': instance.audioPath,
      'duration': instance.duration,
      'position': instance.position,
    };
