import 'package:dio/dio.dart';

import '../models/cancellation_record.dart';
import '../models/journey.dart';
import '../services/backend_api_client.dart';
import 'repository_interfaces.dart';

class BackendJourneyRepository implements JourneyRepository {
  BackendJourneyRepository(this._client);
  final BackendApiClient _client;

  @override
  Future<RepositoryResult<List<JourneyOccurrence>>> getJourneys() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/journeys/next');
      final journey = response.data!['journey'] as Map<String, dynamic>?;
      if (journey == null) return const RepositoryResult.data([]);
      return RepositoryResult.data([_mapJourney(journey)]);
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  JourneyOccurrence _mapJourney(Map<String, dynamic> json) {
    final members = (json['members'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final memberIds = members.map((m) => m['id'] as String).toList();
    final attendance = members.map(_mapAttendance).toList();
    final cancellations = (json['cancellations'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_mapCancellation)
        .toList();
    final stateName = json['state'] as String? ?? 'scheduled';
    final scheduledFor = DateTime.tryParse(json['scheduledFor'] as String? ?? '') ?? DateTime.now();
    return JourneyOccurrence(
      id: json['id'] as String,
      circleId: json['circleId'] as String,
      date: scheduledFor,
      departureWindowStartMinutes: 0,
      departureWindowEndMinutes: 0,
      arrivalTargetMinutes: 0,
      worksiteId: '',
      status: JourneyStatus.values.byName(stateName),
      memberIds: memberIds,
      attendance: attendance,
      backupPlan: JourneyBackupPlan(primaryDriverId: memberIds.isEmpty ? '' : memberIds.first),
      cancellation: cancellations.isEmpty ? null : cancellations.first,
    );
  }

  JourneyAttendance _mapAttendance(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'unsure';
    return JourneyAttendance(
      profileId: json['id'] as String,
      status: _attendanceStatus(statusName),
      updatedAt: DateTime.now(),
    );
  }

  JourneyAttendanceStatus _attendanceStatus(String status) => switch (status) {
        'travelling' => JourneyAttendanceStatus.confirmed,
        'notTravelling' => JourneyAttendanceStatus.notTravelling,
        _ => JourneyAttendanceStatus.undecided,
      };

  CancellationRecord _mapCancellation(Map<String, dynamic> json) => CancellationRecord(
        id: json['id'] as String,
        journeyId: '',
        cancelledByProfileId: '',
        actor: CancellationActor.driver,
        cancelledAt: DateTime.now(),
        affectedProfileIds: const [],
        reason: json['reason'] as String?,
      );
}
