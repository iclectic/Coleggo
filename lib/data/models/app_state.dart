import 'commute.dart';
import 'commuter_profile.dart';
import 'ride_request.dart';

enum AppThemePreference { system, light, dark }

class AppState {
  const AppState({
    this.isLoading = false,
    this.onboardingComplete = false,
    this.selectedWorkplaceId,
    this.selectedWorksiteId,
    this.workEmail,
    this.workplaceVerified = false,
    this.profile,
    this.commute,
    this.requests = const [],
    this.themePreference = AppThemePreference.system,
    this.selectedTab = 0,
    this.errorMessage,
  });

  final bool isLoading;
  final bool onboardingComplete;
  final String? selectedWorkplaceId;
  final String? selectedWorksiteId;
  final String? workEmail;
  final bool workplaceVerified;
  final CommuterProfile? profile;
  final Commute? commute;
  final List<RideRequest> requests;
  final AppThemePreference themePreference;
  final int selectedTab;
  final String? errorMessage;

  bool get setupComplete => profile != null && commute != null;

  AppState copyWith({
    bool? isLoading,
    bool? onboardingComplete,
    String? selectedWorkplaceId,
    String? selectedWorksiteId,
    String? workEmail,
    bool? workplaceVerified,
    CommuterProfile? profile,
    Commute? commute,
    List<RideRequest>? requests,
    AppThemePreference? themePreference,
    int? selectedTab,
    String? errorMessage,
    bool clearError = false,
  }) => AppState(
    isLoading: isLoading ?? this.isLoading,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    selectedWorkplaceId: selectedWorkplaceId ?? this.selectedWorkplaceId,
    selectedWorksiteId: selectedWorksiteId ?? this.selectedWorksiteId,
    workEmail: workEmail ?? this.workEmail,
    workplaceVerified: workplaceVerified ?? this.workplaceVerified,
    profile: profile ?? this.profile,
    commute: commute ?? this.commute,
    requests: requests ?? this.requests,
    themePreference: themePreference ?? this.themePreference,
    selectedTab: selectedTab ?? this.selectedTab,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'onboardingComplete': onboardingComplete,
    'selectedWorkplaceId': selectedWorkplaceId,
    'selectedWorksiteId': selectedWorksiteId,
    'workEmail': workEmail,
    'workplaceVerified': workplaceVerified,
    'profile': profile?.toJson(),
    'commute': commute?.toJson(),
    'requests': requests.map((request) => request.toJson()).toList(),
    'themePreference': themePreference.name,
    'selectedTab': selectedTab,
  };

  factory AppState.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) return const AppState();
    return AppState(
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      selectedWorkplaceId: json['selectedWorkplaceId'] as String?,
      selectedWorksiteId: json['selectedWorksiteId'] as String?,
      workEmail: json['workEmail'] as String?,
      workplaceVerified: json['workplaceVerified'] as bool? ?? false,
      profile: json['profile'] == null
          ? null
          : CommuterProfile.fromJson(json['profile'] as Map<String, dynamic>),
      commute: json['commute'] == null
          ? null
          : Commute.fromJson(json['commute'] as Map<String, dynamic>),
      requests: (json['requests'] as List<dynamic>? ?? const [])
          .map(
            (request) => RideRequest.fromJson(request as Map<String, dynamic>),
          )
          .toList(),
      themePreference: AppThemePreference.values.byName(
        json['themePreference'] as String? ?? 'system',
      ),
      selectedTab: json['selectedTab'] as int? ?? 0,
    );
  }
}
