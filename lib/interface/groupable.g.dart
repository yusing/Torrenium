// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groupable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Groupable _$GroupableFromJson(Map<String, dynamic> json) => Groupable(
      name: json['name'] as String,
      parent: json['parent'] == null
          ? null
          : Groupable.fromJson(json['parent'] as Map<String, dynamic>),
    )
      ..group = json['group'] as String?
      ..coverUrl = json['coverUrl'] as String?;

Map<String, dynamic> _$GroupableToJson(Groupable instance) => <String, dynamic>{
      'name': instance.name,
      'parent': instance.parent,
      'group': instance.group,
      'coverUrl': instance.coverUrl,
    };
