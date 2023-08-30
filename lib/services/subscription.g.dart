// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
      providerName: json['providerName'] as String,
      keyword: json['keyword'] as String,
      category: json['category'] as String?,
      author: json['author'] as String?,
    );

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'providerName': instance.providerName,
      'keyword': instance.keyword,
      'category': instance.category,
      'author': instance.author,
    };
