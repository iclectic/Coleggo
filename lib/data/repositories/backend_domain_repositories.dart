import 'package:dio/dio.dart';

import '../models/commuter_profile.dart';
import '../models/match_result.dart';
import '../models/reliability_profile.dart';
import '../models/workplace.dart';
import '../models/workplace_verification.dart';
import '../services/backend_api_client.dart';
import '../services/matching_service.dart';
import 'repository_interfaces.dart';

class BackendWorkplaceRepository implements WorkplaceRepository {
  BackendWorkplaceRepository(this._client);
  final BackendApiClient _client;
  List<Workplace>? _cache;

  @override
  List<Workplace> getWorkplaces() => _cache ?? const [];

  Future<RepositoryResult<List<Workplace>>> load() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/workplaces');
      final workplaces = (response.data!['workplaces'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mapWorkplace)
          .toList();
      _cache = workplaces;
      return RepositoryResult.data(workplaces);
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  Workplace _mapWorkplace(Map<String, dynamic> json) => Workplace(
        id: json['id'] as String,
        name: json['name'] as String,
        industry: json['domain'] as String? ?? 'workplace',
        worksites: (json['worksites'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(
              (worksite) => Worksite(
                id: worksite['id'] as String,
                name: worksite['name'] as String,
                area: worksite['name'] as String,
              ),
            )
            .toList(),
      );
}

class BackendMatchRepository implements MatchRepository {
  BackendMatchRepository(this._client, {MatchingService? fallback})
      : _fallback = fallback ?? const MatchingService();

  final BackendApiClient _client;
  final MatchingService _fallback;
  final Map<String, List<MatchResult>> _cacheByProfile = {};

  @override
  List<MatchResult> getMatches(CommuterProfile profile) {
    return _cacheByProfile[profile.id] ?? const [];
  }

  @override
  MatchResult getMatch(CommuterProfile profile, String candidateId) {
    final matches = getMatches(profile);
    return matches.firstWhere(
      (match) => match.profile.id == candidateId,
      orElse: () => _fallback.score(profile, profile),
    );
  }

  Future<RepositoryResult<List<MatchResult>>> loadMatches(
    CommuterProfile profile,
  ) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/matches');
      final matches = (response.data!['matches'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_mapMatch)
          .toList();
      _cacheByProfile[profile.id] = matches;
      return RepositoryResult.data(matches);
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }

  MatchResult _mapMatch(Map<String, dynamic> json) {
    final profileJson = json['profile'] as Map<String, dynamic>;
    final breakdownJson =
        json['breakdown'] as Map<String, dynamic>? ?? const {};
    final positives = (json['positiveReasons'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_mapReason)
        .toList();
    final limitations = (json['limitations'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_mapReason)
        .toList();
    return MatchResult(
      profile: CommuterProfile(
        id: profileJson['id'] as String,
        firstName: profileJson['firstName'] as String,
        initials: profileJson['initials'] as String,
        role: CommuteRole.values.byName(profileJson['role'] as String),
        workplaceId: '',
        worksiteId: profileJson['worksiteId'] as String? ?? '',
        homeArea: profileJson['homeArea'] as String,
        corridor: profileJson['corridor'] as String,
        days: (profileJson['days'] as List<dynamic>).cast<int>().toSet(),
        arrivalMinutes: profileJson['arrivalMinutes'] as int,
        departureMinutes: profileJson['departureMinutes'] as int,
        availableSeats: profileJson['availableSeats'] as int? ?? 0,
        vehicleSummary: profileJson['vehicleSummary'] as String?,
        verifiedWorkplace: true,
      ),
      score: json['score'] as int,
      level: MatchLevel.values.byName(json['level'] as String),
      breakdown: MatchBreakdown(
        worksite: breakdownJson['worksite'] as int? ?? 0,
        area: breakdownJson['area'] as int? ?? 0,
        time: breakdownJson['time'] as int? ?? 0,
        days: breakdownJson['days'] as int? ?? 0,
        role: breakdownJson['role'] as int? ?? 0,
        seats: breakdownJson['seats'] as int? ?? 0,
        recurring: breakdownJson['recurring'] as int? ?? 0,
      ),
      positiveReasons: positives,
      limitations: limitations,
      isEligible: json['isEligible'] as bool? ?? false,
      estimated: true,
    );
  }

  MatchReason _mapReason(Map<String, dynamic> json) => MatchReason(
        type: MatchReasonType.values.byName(json['type'] as String),
        message: json['message'] as String,
        estimated: json['estimated'] as bool? ?? false,
      );
}

class BackendReliabilityRepository implements ReliabilityRepository {
  BackendReliabilityRepository(this._client);
  final BackendApiClient _client;

  @override
  Future<RepositoryResult<CommuteReliabilityProfile>> getForProfile(
    String id,
  ) async {
    try {
      final path = id.isEmpty ? '/reliability/me' : '/reliability/$id';
      final response = await _client.get<Map<String, dynamic>>(path);
      final json = response.data!['reliability'] as Map<String, dynamic>;
      return RepositoryResult.data(
        CommuteReliabilityProfile(
          profileId: json['profileId'] as String,
          workplaceVerified: json['workplaceVerified'] as bool? ?? true,
          signals: (json['signals'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .map(
                (signal) => ReliabilitySignal(
                  type: ReliabilitySignalType.values.byName(
                    signal['type'] as String,
                  ),
                  label: signal['label'] as String,
                  count: signal['count'] as int,
                  warning: signal['warning'] as bool? ?? false,
                ),
              )
              .toList(),
        ),
      );
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }
}

class BackendWorkplaceVerificationRepository
    implements WorkplaceVerificationRepository {
  BackendWorkplaceVerificationRepository(this._client);
  final BackendApiClient _client;

  @override
  Future<RepositoryResult<WorkplaceVerificationSession>> start({
    required String workplaceId,
    required String worksiteId,
    required String email,
  }) async {
    final now = DateTime.now();
    return RepositoryResult.data(
      WorkplaceVerificationSession(
        id: 'backend-session',
        workplaceId: workplaceId,
        worksiteId: worksiteId,
        email: email,
        status: WorkplaceVerificationStatus.codeSent,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
      ),
    );
  }

  @override
  Future<RepositoryResult<bool>> verify({
    required String workplaceId,
    required String worksiteId,
    required String email,
    required String code,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/verify-workplace',
        data: {'email': email},
      );
      return RepositoryResult.data(response.data!['verified'] as bool);
    } on DioException catch (e) {
      return RepositoryResult.failure(handleDioError(e));
    }
  }
}
