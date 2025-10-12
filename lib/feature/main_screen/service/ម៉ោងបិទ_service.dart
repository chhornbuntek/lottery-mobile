import '../api/ម៉ោងបិទ_api.dart';

class ClosingTimePost {
  final int id;
  final int? closingTimeId;
  final String postId;
  final String? monday;
  final String? tuesday;
  final String? wednesday;
  final String? thursday;
  final String? friday;
  final String? saturday;
  final String? sunday;
  final bool vip;
  final bool hasActions;

  ClosingTimePost({
    required this.id,
    this.closingTimeId,
    required this.postId,
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
    required this.vip,
    required this.hasActions,
  });

  factory ClosingTimePost.fromMap(Map<String, dynamic> map) {
    return ClosingTimePost(
      id: map['id'],
      closingTimeId: map['closing_time_id'],
      postId: map['post_id'],
      monday: map['monday'],
      tuesday: map['tuesday'],
      wednesday: map['wednesday'],
      thursday: map['thursday'],
      friday: map['friday'],
      saturday: map['saturday'],
      sunday: map['sunday'],
      vip: map['vip'] ?? false,
      hasActions: map['has_actions'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'closing_time_id': closingTimeId,
      'post_id': postId,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
      'vip': vip,
      'has_actions': hasActions,
    };
  }
}

class ClosingTime {
  final int id;
  final String timeName;
  final String startTime;
  final String endTime;
  final bool vipEnabled;
  final List<ClosingTimePost> posts;

  ClosingTime({
    required this.id,
    required this.timeName,
    required this.startTime,
    required this.endTime,
    required this.vipEnabled,
    required this.posts,
  });

  factory ClosingTime.fromMap(Map<String, dynamic> map) {
    List<ClosingTimePost> posts = [];

    if (map['closing_time_posts'] != null) {
      posts = (map['closing_time_posts'] as List)
          .map((post) => ClosingTimePost.fromMap(post))
          .toList();
    }

    return ClosingTime(
      id: map['id'],
      timeName: map['time_name'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      vipEnabled: map['vip_enabled'] ?? false,
      posts: posts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time_name': timeName,
      'start_time': startTime,
      'end_time': endTime,
      'vip_enabled': vipEnabled,
      'closing_time_posts': posts.map((post) => post.toMap()).toList(),
    };
  }

  /// Format time from HH:MM:SS to HH:MM
  String formatTime(String? time) {
    if (time == null) return '';
    if (time.length >= 5) {
      return time.substring(0, 5); // HH:MM
    }
    return time;
  }

  /// Get time for specific day of week
  String getTimeForDay(String dayOfWeek) {
    switch (dayOfWeek.toLowerCase()) {
      case 'monday':
        return formatTime(posts.isNotEmpty ? posts.first.monday : null);
      case 'tuesday':
        return formatTime(posts.isNotEmpty ? posts.first.tuesday : null);
      case 'wednesday':
        return formatTime(posts.isNotEmpty ? posts.first.wednesday : null);
      case 'thursday':
        return formatTime(posts.isNotEmpty ? posts.first.thursday : null);
      case 'friday':
        return formatTime(posts.isNotEmpty ? posts.first.friday : null);
      case 'saturday':
        return formatTime(posts.isNotEmpty ? posts.first.saturday : null);
      case 'sunday':
        return formatTime(posts.isNotEmpty ? posts.first.sunday : null);
      default:
        return '';
    }
  }
}

class ClosingTimeService {
  /// Get all closing times
  static Future<List<ClosingTime>> getAllClosingTimes() async {
    try {
      final response = await ClosingTimeApi.getAllClosingTimes();
      return response.map((map) => ClosingTime.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get closing times: $e');
    }
  }

  /// Get closing times by category
  static Future<List<ClosingTime>> getClosingTimesByCategory(
    String category,
  ) async {
    try {
      final response = await ClosingTimeApi.getClosingTimesByCategory(category);
      return response.map((map) => ClosingTime.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get closing times by category: $e');
    }
  }

  /// Get closing time posts for a specific closing time
  static Future<List<ClosingTimePost>> getClosingTimePosts(
    int closingTimeId,
  ) async {
    try {
      final response = await ClosingTimeApi.getClosingTimePosts(closingTimeId);
      return response.map((map) => ClosingTimePost.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get closing time posts: $e');
    }
  }

  /// Group closing times by category
  static Map<String, List<ClosingTime>> groupClosingTimesByCategory(
    List<ClosingTime> closingTimes,
  ) {
    Map<String, List<ClosingTime>> grouped = {};

    for (var closingTime in closingTimes) {
      String category = _getCategoryFromTimeName(closingTime.timeName);
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(closingTime);
    }

    return grouped;
  }

  /// Extract category from time name
  static String _getCategoryFromTimeName(String timeName) {
    if (timeName.contains('ខ្មែរVIP')) {
      return 'khmer-vip';
    } else if (timeName.contains('យួន')) {
      return 'vietnam';
    } else if (timeName.contains('អន្តរជាតិ')) {
      return 'international';
    } else if (timeName.contains('ថៃ')) {
      return 'thai';
    }
    return 'other';
  }
}
