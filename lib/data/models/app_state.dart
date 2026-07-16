import 'cancellation_record.dart';
import 'commute.dart';
import 'commute_circle.dart';
import 'commute_request.dart';
import 'commuter_profile.dart';
import 'journey.dart';
import 'message_thread.dart';
import 'notification_record.dart';
import 'reliability_profile.dart';
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
    this.commuteRequests = const [],
    this.circles = const [],
    this.journeys = const [],
    this.reliabilityProfiles = const [],
    this.cancellationHistory = const [],
    this.messageThreads = const [],
    this.messageReports = const [],
    this.notifications = const [],
    this.activeCircleId,
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
  final List<CommuteRequest> commuteRequests;
  final List<CommuteCircle> circles;
  final List<JourneyOccurrence> journeys;
  final List<CommuteReliabilityProfile> reliabilityProfiles;
  final List<CancellationRecord> cancellationHistory;
  final List<MessageThread> messageThreads;
  final List<MessageModerationReport> messageReports;
  final List<CommuteNotification> notifications;
  final String? activeCircleId;
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
    List<CommuteRequest>? commuteRequests,
    List<CommuteCircle>? circles,
    List<JourneyOccurrence>? journeys,
    List<CommuteReliabilityProfile>? reliabilityProfiles,
    List<CancellationRecord>? cancellationHistory,
    List<MessageThread>? messageThreads,
    List<MessageModerationReport>? messageReports,
    List<CommuteNotification>? notifications,
    String? activeCircleId,
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
    commuteRequests: commuteRequests ?? this.commuteRequests,
    circles: circles ?? this.circles,
    journeys: journeys ?? this.journeys,
    reliabilityProfiles: reliabilityProfiles ?? this.reliabilityProfiles,
    cancellationHistory: cancellationHistory ?? this.cancellationHistory,
    messageThreads: messageThreads ?? this.messageThreads,
    messageReports: messageReports ?? this.messageReports,
    notifications: notifications ?? this.notifications,
    activeCircleId: activeCircleId ?? this.activeCircleId,
    themePreference: themePreference ?? this.themePreference,
    selectedTab: selectedTab ?? this.selectedTab,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': 4,
    'onboardingComplete': onboardingComplete,
    'selectedWorkplaceId': selectedWorkplaceId,
    'selectedWorksiteId': selectedWorksiteId,
    'workEmail': workEmail,
    'workplaceVerified': workplaceVerified,
    'profile': profile?.toJson(),
    'commute': commute?.toJson(),
    'requests': requests.map((request) => request.toJson()).toList(),
    'commuteRequests': commuteRequests
        .map((request) => request.toJson())
        .toList(),
    'circles': circles.map((circle) => circle.toJson()).toList(),
    'journeys': journeys.map((journey) => journey.toJson()).toList(),
    'reliabilityProfiles': reliabilityProfiles
        .map((profile) => profile.toJson())
        .toList(),
    'cancellationHistory': cancellationHistory
        .map((record) => record.toJson())
        .toList(),
    'messageThreads': messageThreads.map((thread) => thread.toJson()).toList(),
    'messageReports': messageReports.map((report) => report.toJson()).toList(),
    'notifications': notifications
        .map((notification) => notification.toJson())
        .toList(),
    'activeCircleId': activeCircleId,
    'themePreference': themePreference.name,
    'selectedTab': selectedTab,
  };

  factory AppState.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version != 1 && version != 2 && version != 3 && version != 4) {
      return const AppState();
    }
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
      commuteRequests: version == 1
          ? const []
          : (json['commuteRequests'] as List<dynamic>? ?? const [])
                .map(
                  (request) =>
                      CommuteRequest.fromJson(request as Map<String, dynamic>),
                )
                .toList(),
      circles: version == 1
          ? const []
          : (json['circles'] as List<dynamic>? ?? const [])
                .map(
                  (circle) =>
                      CommuteCircle.fromJson(circle as Map<String, dynamic>),
                )
                .toList(),
      journeys: version == 1
          ? const []
          : (json['journeys'] as List<dynamic>? ?? const [])
                .map(
                  (journey) => JourneyOccurrence.fromJson(
                    journey as Map<String, dynamic>,
                  ),
                )
                .toList(),
      reliabilityProfiles: version == 1
          ? const []
          : (json['reliabilityProfiles'] as List<dynamic>? ?? const [])
                .map(
                  (profile) => CommuteReliabilityProfile.fromJson(
                    profile as Map<String, dynamic>,
                  ),
                )
                .toList(),
      cancellationHistory: version == 1
          ? const []
          : (json['cancellationHistory'] as List<dynamic>? ?? const [])
                .map(
                  (record) => CancellationRecord.fromJson(
                    record as Map<String, dynamic>,
                  ),
                )
                .toList(),
      messageThreads: version >= 3
          ? (json['messageThreads'] as List<dynamic>? ?? const [])
                .map(
                  (thread) =>
                      MessageThread.fromJson(thread as Map<String, dynamic>),
                )
                .toList()
          : const [],
      messageReports: version >= 3
          ? (json['messageReports'] as List<dynamic>? ?? const [])
                .map(
                  (report) => MessageModerationReport.fromJson(
                    report as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
      notifications: version >= 4
          ? (json['notifications'] as List<dynamic>? ?? const [])
                .map(
                  (notification) => CommuteNotification.fromJson(
                    notification as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
      activeCircleId: version == 1 ? null : json['activeCircleId'] as String?,
      themePreference: AppThemePreference.values.byName(
        json['themePreference'] as String? ?? 'system',
      ),
      selectedTab: json['selectedTab'] as int? ?? 0,
    );
  }
}
