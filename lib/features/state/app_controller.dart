import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/app_state.dart';
import '../../data/models/commute.dart';
import '../../data/models/commuter_profile.dart';
import '../../data/models/ride_request.dart';
import 'providers.dart';

class AppController extends Notifier<AppState> {
  @override
  AppState build() {
    Future<void>.microtask(_restore);
    return const AppState(isLoading: true);
  }

  Future<void> _restore() async {
    final restored = await ref.read(commuteRepositoryProvider).loadState();
    state = restored.copyWith(isLoading: false);
  }

  Future<void> _setAndPersist(AppState next) async {
    state = next.copyWith(isLoading: false, clearError: true);
    try {
      await ref.read(commuteRepositoryProvider).saveState(state);
    } on Object {
      state = state.copyWith(
        errorMessage:
            'Your change was kept for this session but could not be saved.',
      );
    }
  }

  Future<void> completeOnboarding() =>
      _setAndPersist(state.copyWith(onboardingComplete: true));

  Future<void> selectWorkplace(String workplaceId, String worksiteId) =>
      _setAndPersist(
        state.copyWith(
          selectedWorkplaceId: workplaceId,
          selectedWorksiteId: worksiteId,
          workplaceVerified: false,
        ),
      );

  Future<bool> verifyWorkEmail(String email, String code) async {
    if (code != AppConstants.mockCode) return false;
    await _setAndPersist(
      state.copyWith(workEmail: email, workplaceVerified: true),
    );
    return true;
  }

  Future<void> saveProfileAndCommute(CommuterProfile profile) async {
    final commute = ref.read(commuteRepositoryProvider).createFor(profile);
    final requests = state.requests.isEmpty
        ? ref.read(rideRequestRepositoryProvider).seededRequests()
        : state.requests;
    await _setAndPersist(
      state.copyWith(profile: profile, commute: commute, requests: requests),
    );
  }

  Future<void> updateCommute(Commute commute) {
    final profile = state.profile;
    final updatedProfile = profile?.copyWith(
      homeArea: commute.homeArea,
      corridor: MockData.areaCorridors[commute.homeArea],
      worksiteId: commute.worksiteId,
      days: commute.days,
      arrivalMinutes: commute.arrivalMinutes,
      departureMinutes: commute.departureMinutes,
    );
    return _setAndPersist(
      state.copyWith(commute: commute, profile: updatedProfile),
    );
  }

  Future<bool> sendRequest(String profileId, RequestKind kind) async {
    final duplicate = state.requests.any(
      (request) =>
          request.profileId == profileId &&
          request.status == RequestStatus.pending,
    );
    if (duplicate) return false;
    final profile = ref.read(profileRepositoryProvider).getById(profileId);
    final request = RideRequest(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      profileId: profileId,
      direction: RequestDirection.outgoing,
      kind: kind,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      recurringDays: state.profile?.days.intersection(profile.days) ?? const {},
    );
    await _setAndPersist(
      state.copyWith(requests: [...state.requests, request]),
    );
    return true;
  }

  Future<void> updateRequest(String id, RequestStatus status) async {
    final requests = state.requests.map((request) {
      if (request.id != id) return request;
      final allowed = switch ((request.direction, request.status, status)) {
        (
          RequestDirection.incoming,
          RequestStatus.pending,
          RequestStatus.accepted,
        ) =>
          true,
        (
          RequestDirection.incoming,
          RequestStatus.pending,
          RequestStatus.declined,
        ) =>
          true,
        (
          RequestDirection.outgoing,
          RequestStatus.pending,
          RequestStatus.cancelled,
        ) =>
          true,
        _ => false,
      };
      return allowed ? request.copyWith(status: status) : request;
    }).toList();
    await _setAndPersist(state.copyWith(requests: requests));
  }

  Future<void> setTheme(AppThemePreference preference) =>
      _setAndPersist(state.copyWith(themePreference: preference));

  Future<void> selectTab(int index) =>
      _setAndPersist(state.copyWith(selectedTab: index));

  Future<void> reset() async {
    await ref.read(commuteRepositoryProvider).clearState();
    state = const AppState();
  }

  void dismissError() => state = state.copyWith(clearError: true);
}
