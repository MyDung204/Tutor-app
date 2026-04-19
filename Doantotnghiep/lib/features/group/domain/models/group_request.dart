

class GroupRequest {
  final String id;
  final String creatorId;
  final String creatorName;
  final String topic;
  final String subject;
  final String gradeLevel;
  final double pricePerSession; // Per person
  final String location;
  final String description;
  final int currentMembers;
  final int maxMembers;
  final int minMembers;
  final DateTime createdAt;
  final DateTime startTime;
  final String status; // 'open', 'full', 'closed'
  final String? membershipStatus; // 'pending', 'approved', 'rejected' or null
  final int pendingRequestsCount;
  final bool hasNewMessages;

  GroupRequest({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.topic,
    required this.subject,
    required this.gradeLevel,
    required this.pricePerSession,
    required this.location,
    required this.description,
    this.currentMembers = 1,
    required this.maxMembers,
    this.minMembers = 2,
    required this.createdAt,
    required this.startTime,
    this.status = 'open',
    this.membershipStatus,
    this.pendingRequestsCount = 0,
    this.hasNewMessages = false,
  });

  GroupRequest copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? topic,
    String? subject,
    String? gradeLevel,
    double? pricePerSession,
    String? location,
    String? description,
    int? currentMembers,
    int? maxMembers,
    int? minMembers,
    DateTime? createdAt,
    DateTime? startTime,
    String? status,
    String? membershipStatus,
  }) {
    return GroupRequest(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      topic: topic ?? this.topic,
      subject: subject ?? this.subject,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      pricePerSession: pricePerSession ?? this.pricePerSession,
      location: location ?? this.location,
      description: description ?? this.description,
      currentMembers: currentMembers ?? this.currentMembers,
      maxMembers: maxMembers ?? this.maxMembers,
      minMembers: minMembers ?? this.minMembers,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      status: status ?? this.status,
      membershipStatus: membershipStatus ?? this.membershipStatus,
    );
  }

  factory GroupRequest.fromJson(Map<String, dynamic> json) {
    if (json['pending_requests_count'] != null) {
      print('DEBUG: Group ${json['topic']} has pending: ${json['pending_requests_count']}');
    }
    return GroupRequest(
      id: json['id'].toString(),
      creatorId: json['creator_id']?.toString() ?? '',
      creatorName: json['creator']?['name'] ?? 'Unknown',
      topic: json['topic'] ?? '',
      subject: json['subject'] ?? '',
      gradeLevel: json['grade_level'] ?? '',
      pricePerSession: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      location: json['location'] ?? 'Online',
      description: json['description'] ?? '',
      currentMembers: json['current_members'] ?? 1,
      maxMembers: json['max_members'] ?? 5,
      minMembers: 2,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      startTime: DateTime.now().add(const Duration(days: 1)),
      status: json['status'] ?? 'open',
      membershipStatus: json['membership_status'],
      pendingRequestsCount: json['pending_requests_count'] ?? 0,
      hasNewMessages: json['has_new_messages'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'topic': topic,
      'subject': subject,
      'gradeLevel': gradeLevel,
      'pricePerSession': pricePerSession,
      'location': location,
      'description': description,
      'currentMembers': currentMembers,
      'maxMembers': maxMembers,
      'minMembers': minMembers,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startTime': startTime.millisecondsSinceEpoch,
      'status': status,
    };
  }
}
