import 'package:json_annotation/json_annotation.dart';

part 'wikipedia_page.g.dart';

@JsonSerializable()
class WikipediaPage {
  final int pageId;
  final String title;
  final String? extract;
  final String? thumbnail;

  const WikipediaPage({
    required this.pageId,
    required this.title,
    this.extract,
    this.thumbnail,
  });

  factory WikipediaPage.fromJson(Map<String, dynamic> json) => _$WikipediaPageFromJson(json);
  Map<String, dynamic> toJson() => _$WikipediaPageToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WikipediaPage && 
      runtimeType == other.runtimeType && 
      pageId == other.pageId;

  @override
  int get hashCode => pageId.hashCode;

  @override
  String toString() => 'WikipediaPage(pageId: $pageId, title: $title)';
}