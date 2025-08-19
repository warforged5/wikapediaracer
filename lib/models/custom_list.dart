import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'custom_list.g.dart';

@JsonSerializable()
class CustomList {
  final String id;
  final String name;
  final List<String> pages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomList({
    required this.id,
    required this.name,
    required this.pages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomList.create({
    required String name,
    required List<String> pages,
  }) {
    final now = DateTime.now();
    return CustomList(
      id: const Uuid().v4(),
      name: name,
      pages: pages,
      createdAt: now,
      updatedAt: now,
    );
  }

  CustomList copyWith({
    String? id,
    String? name,
    List<String>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomList(
      id: id ?? this.id,
      name: name ?? this.name,
      pages: pages ?? this.pages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory CustomList.fromJson(Map<String, dynamic> json) => _$CustomListFromJson(json);
  Map<String, dynamic> toJson() => _$CustomListToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomList && 
      runtimeType == other.runtimeType && 
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomList(id: $id, name: $name, pages: ${pages.length})';
}