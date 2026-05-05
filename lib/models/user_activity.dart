class UserActivity {
  final String activityId;
  final String ownerId;
  final String type;
  final String? description;
  final String? ip;
  final DateTime date;

  UserActivity({
    required this.activityId,
    required this.ownerId,
    required this.type,
    this.description,
    this.ip,
    required this.date,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      activityId: json['activity_id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description'],
      ip: json['ip'],
      date: DateTime.parse(json['date']),
    );
  }
}
