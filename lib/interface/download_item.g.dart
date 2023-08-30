// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DownloadItem _$DownloadItemFromJson(Map<String, dynamic> json) => DownloadItem(
      name: json['name'] as String,
      parent: json['parent'] == null
          ? null
          : Groupable.fromJson(json['parent'] as Map<String, dynamic>),
    )
      ..group = json['group'] as String?
      ..coverUrl = json['coverUrl'] as String?;

Map<String, dynamic> _$DownloadItemToJson(DownloadItem instance) =>
    <String, dynamic>{
      'name': instance.name,
      'parent': instance.parent,
      'group': instance.group,
      'coverUrl': instance.coverUrl,
    };
