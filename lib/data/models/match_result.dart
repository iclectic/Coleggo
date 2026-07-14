import 'commuter_profile.dart';

class MatchBreakdown {
  const MatchBreakdown({
    required this.area,
    required this.time,
    required this.worksite,
    required this.days,
    required this.role,
  });

  final int area;
  final int time;
  final int worksite;
  final int days;
  final int role;

  int get total => area + time + worksite + days + role;
}

class MatchResult {
  const MatchResult({
    required this.profile,
    required this.score,
    required this.breakdown,
    required this.reasons,
  });

  final CommuterProfile profile;
  final int score;
  final MatchBreakdown breakdown;
  final List<String> reasons;
}
