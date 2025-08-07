// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wikipedia_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WikipediaPage _$WikipediaPageFromJson(Map<String, dynamic> json) =>
    WikipediaPage(
      pageId: (json['pageId'] as num).toInt(),
      title: json['title'] as String,
      extract: json['extract'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );

Map<String, dynamic> _$WikipediaPageToJson(WikipediaPage instance) =>
    <String, dynamic>{
      'pageId': instance.pageId,
      'title': instance.title,
      'extract': instance.extract,
      'thumbnail': instance.thumbnail,
    };
