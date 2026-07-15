import 'commuter_profile.dart';

enum MatchLevel {
  excellent('Excellent match'),
  strong('Strong match'),
  possible('Possible match'),
  limited('Limited match');

  const MatchLevel(this.label);
  final String label;
}

enum MatchReasonType {
  worksite,
  area,
  time,
  days,
  role,
  seats,
  recurring,
  privacy,
}

class MatchReason {
  const MatchReason({
    required this.type,
    required this.message,
    this.estimated = false,
  });

  final MatchReasonType type;
  final String message;
  final bool estimated;
}

class MatchBreakdown {
  const MatchBreakdown({
    required this.worksite,
    required this.area,
    required this.time,
    required this.days,
    required this.role,
    required this.seats,
    required this.recurring,
  });

  final int worksite;
  final int area;
  final int time;
  final int days;
  final int role;
  final int seats;
  final int recurring;

  int get total => worksite + area + time + days + role + seats + recurring;
}

class MatchResult {
  const MatchResult({
    required this.profile,
    required this.score,
    required this.level,
    required this.breakdown,
    required this.positiveReasons,
    required this.limitations,
    required this.isEligible,
    this.estimated = true,
  });

  final CommuterProfile profile;
  final int score;
  final MatchLevel level;
  final MatchBreakdown breakdown;
  final List<MatchReason> positiveReasons;
  final List<MatchReason> limitations;
  final bool isEligible;
  final bool estimated;

  List<String> get reasons =>
      positiveReasons.map((reason) => reason.message).toList();
}
