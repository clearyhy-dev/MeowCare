import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/enums.dart';

class CatModel {
  final String catId;
  final String ownerId;
  final String familyId;
  final String name;
  final String breedId;
  final String avatarUrl;
  final bool isPublic;
  final String ownerNotes;
  final DateTime? birthday;
  final double weight;
  final bool neutered;
  final ActivityLevel activityLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CatModel({
    required this.catId,
    this.ownerId = '',
    this.familyId = '',
    required this.name,
    this.breedId = '',
    this.avatarUrl = '',
    this.isPublic = false,
    this.ownerNotes = '',
    this.birthday,
    this.weight = 0,
    this.neutered = false,
    this.activityLevel = ActivityLevel.medium,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'catId': catId,
      'ownerId': ownerId,
      'familyId': familyId,
      'name': name,
      'breedId': breedId,
      'avatarUrl': avatarUrl,
      'public': isPublic,
      'ownerNotes': ownerNotes,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'weight': weight,
      'neutered': neutered,
      'activityLevel': activityLevel.value,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  static CatModel fromMap(Map<String, dynamic> map, String catId) {
    final birthday = map['birthday'];
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];
    return CatModel(
      catId: catId,
      ownerId: map['ownerId'] as String? ?? '',
      familyId: map['familyId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      breedId: map['breedId'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      isPublic: map['public'] as bool? ?? false,
      ownerNotes: map['ownerNotes'] as String? ?? '',
      birthday: birthday is Timestamp ? birthday.toDate() : null,
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      neutered: map['neutered'] as bool? ?? false,
      activityLevel: ActivityLevel.fromString(map['activityLevel'] as String?),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }

  CatModel copyWith({
    String? ownerId,
    String? familyId,
    String? name,
    String? breedId,
    String? avatarUrl,
    bool? isPublic,
    String? ownerNotes,
    DateTime? birthday,
    double? weight,
    bool? neutered,
    ActivityLevel? activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CatModel(
      catId: catId,
      ownerId: ownerId ?? this.ownerId,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      breedId: breedId ?? this.breedId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPublic: isPublic ?? this.isPublic,
      ownerNotes: ownerNotes ?? this.ownerNotes,
      birthday: birthday ?? this.birthday,
      weight: weight ?? this.weight,
      neutered: neutered ?? this.neutered,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

