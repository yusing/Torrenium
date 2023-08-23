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
    )
      ..parent = json['parent'] == null
          ? null
          : Groupable.fromJson(json['parent'] as Map<String, dynamic>)
      ..coverUrl = json['coverUrl'] as String?;

Map<String, dynamic> _$WatchHistoryEntryToJson(WatchHistoryEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'parent': instance.parent,
      'coverUrl': instance.coverUrl,
      'path': instance.path,
      'audioPath': instance.audioPath,
      'duration': instance.duration,
      'position': instance.position,
    };
