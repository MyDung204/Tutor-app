import 'package:doantotnghiep/features/tutor/domain/models/badge.dart';

class Tutor {
  final String id;
  final String name;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final double hourlyRate;
  final List<String> subjects;
  final String bio;
  final String location;
  final bool isVerified;
  final String gender;
  final List<String> teachingMode; // ['Online', 'Offline']
  final String address;
  final Map<String, List<String>> weeklySchedule; // e.g. {'2': ['08:00 - 10:00', '14:00 - 16:00'], '3': []}
  final String tier; // 'teacher' | 'student'
  final String userId;
  final String university;
  final String degree;
  final String phone;
  final String videoUrl;
  final List<String> certificates;
  final List<Badge> badges;
  final bool isFavorite;

  Tutor({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.hourlyRate,
    required this.subjects,
    required this.bio,
    required this.location,
    this.isVerified = false,
    required this.gender,
    required this.teachingMode,
    required this.address,
    required this.weeklySchedule,
    this.tier = 'student',
    required this.userId,
    this.university = '',
    this.degree = '',
    this.phone = '',
    this.videoUrl = '',
    this.certificates = const [],
    this.badges = const [],
    this.isFavorite = false,
  });

  factory Tutor.fromJson(Map<String, dynamic> json) {
    return Tutor(
      id: json['id'].toString(), 
      name: json['name'],
      avatarUrl: json['avatar_url'] ?? '', 
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      hourlyRate: (json['hourly_rate'] ?? 0).toDouble(),
      subjects: List<String>.from(json['subjects'] ?? []),
      bio: json['bio'] ?? '',
      location: json['location'] ?? '',
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      gender: json['gender'] ?? 'Khác',
      teachingMode: List<String>.from(json['teaching_mode'] ?? ['Online']),
      address: json['address'] ?? '',
      university: json['university'] ?? '',
      degree: json['degree'] ?? '',
      phone: json['phone'] ?? '',
      weeklySchedule: (json['weekly_schedule'] is Map)
          ? Map<String, List<String>>.from(
              (json['weekly_schedule'] as Map).map(
                (key, value) => MapEntry(key.toString(), List<String>.from(value)),
              ),
            )
          : {},
      tier: json['tier'] ?? 'student',
      userId: (json['user_id'] ?? json['id']).toString(),
      videoUrl: json['video_url'] ?? '',
      certificates: List<String>.from(json['certificates'] ?? []),
      badges: (json['user']?['badges'] as List?)
          ?.map((e) => Badge.fromJson(e))
          .toList() ?? 
          [],
      isFavorite: json['is_favorite'] == 1 || json['is_favorite'] == true,
    );
  }
  
  Tutor copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    double? rating,
    int? reviewCount,
    double? hourlyRate,
    List<String>? subjects,
    String? bio,
    String? location,
    bool? isVerified,
    String? gender,
    List<String>? teachingMode,
    String? address,
    Map<String, List<String>>? weeklySchedule,
    String? tier,
    String? userId,
    String? university,
    String? degree,
    String? phone,
    String? videoUrl,
    List<String>? certificates,
    List<Badge>? badges,
    bool? isFavorite,
  }) {
    return Tutor(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      subjects: subjects ?? this.subjects,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      gender: gender ?? this.gender,
      teachingMode: teachingMode ?? this.teachingMode,
      address: address ?? this.address,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      tier: tier ?? this.tier,
      userId: userId ?? this.userId,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      phone: phone ?? this.phone,
      videoUrl: videoUrl ?? this.videoUrl,
      certificates: certificates ?? this.certificates,
      badges: badges ?? this.badges,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
