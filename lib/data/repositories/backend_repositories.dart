import 'package:dio/dio.dart';

import '../models/commuter_profile.dart';
import '../models/notification_record.dart';
import '../services/backend_api_client.dart';
import 'repository_interfaces.dart';

class BackendAuthRepository implements AuthRepository {
  BackendAuthRepository(this._client);
  final BackendApiClient _client;

  @override
  Future<RepositoryResult<AuthUser>> register({
    required String email,
    required String password,
    required String firstName,
    required String initials,
    required String worksiteId,
    required String homeArea,
    required String corridor,
    required Set<int> days,
    required int arrivalMinutes,
    required int departureMinutes,
    required CommuteRole role,
    int availableSeats = 0,
    String? vehicleSummary,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'initials': initials,
        'worksiteId': worksiteId,
        'homeArea': homeArea,
        'corridor': corridor,
        'days': days.toList(),
        'arrivalMinutes': arrivalMinutes,
        'departureMinutes': departureMinutes,
        'role': role.name,
        'availableSeats': availableSeats,
        'vehicleSummary': vehicleSummary,
      });
      final data = response.data!;
      await _client.saveToken(data['token'] as String);
      return RepositoryResult.data(_mapAuthUser(data['user'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<RepositoryResult<AuthUser>> login(String email, String password) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data!;
      await _client.saveToken(data['token'] as String);
      return RepositoryResult.data(_mapAuthUser(data['user'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<RepositoryResult<AuthUser>> currentUser() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/auth/me');
      return RepositoryResult.data(_mapAuthUser(response.data!['user'] as Map<String, dynamic>));
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<RepositoryResult<bool>> verifyWorkplaceEmail(String email) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/auth/verify-workplace', data: {'email': email});
      return RepositoryResult.data(response.data!['verified'] as bool);
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<void> logout() => _client.clearToken();

  AuthUser _mapAuthUser(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      profile: profile == null ? null : _mapProfile(profile),
    );
  }

  CommuterProfile _mapProfile(Map<String, dynamic> json) {
    final worksite = json['worksite'] as Map<String, dynamic>?;
    final workplace = worksite?['workplace'] as Map<String, dynamic>?;
    return CommuterProfile(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      initials: json['initials'] as String,
      role: CommuteRole.values.byName(json['role'] as String),
      workplaceId: workplace?['id'] as String? ?? '',
      worksiteId: worksite?['id'] as String? ?? '',
      homeArea: json['homeArea'] as String,
      corridor: json['corridor'] as String,
      days: (json['days'] as List<dynamic>).cast<int>().toSet(),
      arrivalMinutes: json['arrivalMinutes'] as int,
      departureMinutes: json['departureMinutes'] as int,
      availableSeats: json['availableSeats'] as int? ?? 0,
      vehicleSummary: json['vehicleSummary'] as String?,
      verifiedWorkplace: true,
    );
  }
}

class BackendNotificationRepository implements NotificationRepository {
  BackendNotificationRepository(this._client);
  final BackendApiClient _client;

  @override
  Future<RepositoryResult<CommuteNotification>> create({
    required CommuteNotificationType type,
    required String title,
    required String body,
    required CommuteNotificationPriority priority,
    String? contextRoute,
  }) async {
    return RepositoryResult.data(
      CommuteNotification(
        id: 'notification-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        title: title,
        body: body,
        priority: priority,
        contextRoute: contextRoute,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<RepositoryResult<List<CommuteNotification>>> markRead({
    required List<CommuteNotification> notifications,
    required String notificationId,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>('/notifications/$notificationId/read');
    } on DioException {
      // fall through to local update
    }
    return RepositoryResult.data(
      notifications
          .map((n) => n.id == notificationId ? n.copyWith(read: true) : n)
          .toList(),
    );
  }

  @override
  Future<RepositoryResult<List<CommuteNotification>>> markAllRead({
    required List<CommuteNotification> notifications,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>('/notifications/read-all');
    } on DioException {
      // fall through to local update
    }
    return RepositoryResult.data(
      notifications.map((n) => n.copyWith(read: true)).toList(),
    );
  }
}
