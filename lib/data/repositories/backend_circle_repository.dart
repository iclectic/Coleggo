import 'package:dio/dio.dart';

import '../models/commute.dart';
import '../models/commute_circle.dart';
import '../models/commute_request.dart';
import '../models/commuter_profile.dart';
import '../models/shift_pattern.dart';
import '../services/backend_api_client.dart';
import 'repository_interfaces.dart';

class BackendCommuteCircleRepository implements CommuteCircleRepository {
  BackendCommuteCircleRepository(this._client);
  final BackendApiClient _client;

  @override
  Future<RepositoryResult<List<CommuteCircle>>> getCircles() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/circles');
      final circles = (response.data!['circles'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mapCircle)
          .toList();
      return RepositoryResult.data(circles);
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<RepositoryResult<CommuteCircle>> getCircle(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/circles/$id');
      return RepositoryResult.data(_mapCircle(response.data!));
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<RepositoryResult<CommuteRequest>> requestToJoin({
    required List<CommuteRequest> currentRequests,
    required String requesterProfileId,
    required String circleId,
    required Commute commute,
    required CommuterProfile profile,
  }) async {
    final duplicate = currentRequests.any(
      (request) =>
          request.circleId == circleId &&
          request.requesterProfileId == requesterProfileId &&
          request.type == CommuteRequestType.joinCircle &&
          request.isActive,
    );
    if (duplicate) {
      return const RepositoryResult.failure(
        'You already have an active request for this circle.',
      );
    }
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/circles/$circleId/join',
        data: {'message': 'I would like to join this circle for my regular work commute.'},
      );
      final request = _mapRequest(response.data!['request'] as Map<String, dynamic>);
      return RepositoryResult.data(request);
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<RepositoryResult<List<CommuteCircle>>> applyMembershipDecision({
    required List<CommuteCircle> circles,
    required CommuteRequest request,
    required CommuteRequestStatus status,
  }) async {
    if (request.circleId == null) return RepositoryResult.data(circles);
    final endpoint = status == CommuteRequestStatus.accepted ? 'accept' : 'decline';
    try {
      await _client.post<Map<String, dynamic>>(
        '/circles/${request.circleId}/$endpoint',
        data: {'requestId': request.id},
      );
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
    // Refresh circle membership from server.
    final result = await getCircle(request.circleId!);
    if (result.hasError || result.value == null) return RepositoryResult.data(circles);
    return RepositoryResult.data(
      circles.map((c) => c.id == request.circleId ? result.value! : c).toList(),
    );
  }

  @override
  Future<RepositoryResult<List<CommuteCircle>>> pauseParticipation({
    required List<CommuteCircle> circles,
    required String circleId,
    required String profileId,
    required bool paused,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/circles/$circleId/pause-participation',
        data: {'paused': paused},
        idempotencyKey: 'pause-$circleId-$profileId-$paused',
      );
      final refreshed = await getCircles();
      if (refreshed.hasError || refreshed.value == null) {
        return RepositoryResult.data(circles);
      }
      return refreshed;
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  @override
  Future<RepositoryResult<List<CommuteCircle>>> leaveCircle({
    required List<CommuteCircle> circles,
    required String circleId,
    required String profileId,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/circles/$circleId/leave',
        idempotencyKey: 'leave-$circleId-$profileId',
      );
      final refreshed = await getCircles();
      if (refreshed.hasError || refreshed.value == null) {
        return RepositoryResult.data(
          circles.where((circle) => circle.id != circleId).toList(),
        );
      }
      return refreshed;
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  CommuteCircle _mapCircle(Map<String, dynamic> json) {
    final members = (json['members'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_mapMember)
        .toList();
    final stateName = json['state'] as String? ?? 'active';
    final shift = _shiftFor(json['shiftLabel'] as String? ?? 'standardOffice');
    return CommuteCircle(
      id: json['id'] as String,
      name: json['name'] as String,
      workplaceId: '',
      worksiteId: '',
      state: CommuteCircleState.values.byName(stateName),
      members: members,
      days: (json['days'] as List<dynamic>? ?? const []).cast<int>().toSet(),
      departureWindowStartMinutes: shift.departureWindowStartMinutes,
      departureWindowEndMinutes: shift.departureWindowEndMinutes,
      arrivalTargetMinutes: (json['arrivalTargetMinutes'] as int?) ?? shift.endMinutes,
      meetingPointArea: json['meetingPointArea'] as String? ?? 'Public transport stop',
      availableSeats: (json['seats'] as int?) ?? 0,
      rules: const [],
      shiftPattern: shift,
      activity: const [],
      reliabilitySummaries: const [],
    );
  }

  CircleMember _mapMember(Map<String, dynamic> json) => CircleMember(
        profileId: json['id'] as String,
        role: _mapMemberRole(json['role'] as String? ?? 'passenger'),
      );

  CircleMemberRole _mapMemberRole(String role) => switch (role) {
        'organiser' || 'driver' || 'primaryDriver' =>
          CircleMemberRole.primaryDriver,
        'backupDriver' => CircleMemberRole.backupDriver,
        _ => CircleMemberRole.passenger,
      };

  CommuteRequest _mapRequest(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'pending';
    return CommuteRequest(
      id: json['id'] as String,
      requesterProfileId: json['requesterId'] as String? ?? '',
      type: CommuteRequestType.joinCircle,
      status: CommuteRequestStatus.values.byName(statusName),
      intendedDays: const {},
      windowStartMinutes: 0,
      windowEndMinutes: 0,
      worksiteId: '',
      seatsRequired: 1,
      intent: CommuteArrangementIntent.recurring,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      circleId: json['circleId'] as String?,
      message: json['message'] as String?,
    );
  }

  ShiftPattern _shiftFor(String label) => switch (label.toLowerCase()) {
        'early' => ShiftPattern.early,
        'late' => ShiftPattern.late,
        'night' => ShiftPattern.night,
        _ => ShiftPattern.standardOffice,
      };
}
