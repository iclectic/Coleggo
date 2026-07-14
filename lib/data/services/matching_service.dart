import '../mock/mock_data.dart';
import '../models/commuter_profile.dart';
import '../models/match_result.dart';

class MatchingService {
  const MatchingService();

  List<MatchResult> findMatches(
    CommuterProfile user,
    Iterable<CommuterProfile> candidates,
  ) {
    final matches = candidates
        .where((candidate) => candidate.id != user.id)
        .where((candidate) => _rolesCompatible(user, candidate))
        .map((candidate) => score(user, candidate))
        .where((match) => match.score >= 35)
        .toList();
    matches.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      return scoreOrder != 0
          ? scoreOrder
          : a.profile.firstName.compareTo(b.profile.firstName);
    });
    return matches;
  }

  MatchResult score(CommuterProfile user, CommuterProfile candidate) {
    final reasons = <String>[];
    final area = _areaScore(user, candidate, reasons);
    final time = _timeScore(user, candidate, reasons);
    final worksite = user.worksiteId == candidate.worksiteId ? 20 : 0;
    if (worksite == 20) reasons.add('Same worksite');

    final sharedDays = user.days.intersection(candidate.days).length;
    final days = user.days.isEmpty
        ? 0
        : (15 * sharedDays / user.days.length).round();
    if (sharedDays > 0) {
      reasons.add(
        '$sharedDays matching commute ${sharedDays == 1 ? 'day' : 'days'}',
      );
    }

    final role = _rolesCompatible(user, candidate) ? 5 : 0;
    if (candidate.role.canDrive && candidate.availableSeats > 0) {
      reasons.add(
        '${candidate.availableSeats} ${candidate.availableSeats == 1 ? 'seat' : 'seats'} available',
      );
    }

    final breakdown = MatchBreakdown(
      area: area,
      time: time,
      worksite: worksite,
      days: days,
      role: role,
    );
    return MatchResult(
      profile: candidate,
      score: breakdown.total.clamp(0, 100),
      breakdown: breakdown,
      reasons: reasons,
    );
  }

  int _areaScore(
    CommuterProfile user,
    CommuterProfile candidate,
    List<String> reasons,
  ) {
    if (user.homeArea == candidate.homeArea) {
      reasons.add('Starts from the same approximate area');
      return 35;
    }
    if (user.corridor == candidate.corridor) {
      reasons.add('Starts from a nearby area on the same broad corridor');
      return 28;
    }
    final userDirection = MockData.areaCorridors[user.homeArea]
        ?.split(' to ')
        .first;
    final candidateDirection = MockData.areaCorridors[candidate.homeArea]
        ?.split(' to ')
        .first;
    if (userDirection != null && userDirection == candidateDirection) {
      reasons.add('Uses a related area corridor');
      return 18;
    }
    return 6;
  }

  int _timeScore(
    CommuterProfile user,
    CommuterProfile candidate,
    List<String> reasons,
  ) {
    final useDeparture = user.role.canDrive || candidate.role.canDrive;
    final userTime = useDeparture ? user.departureMinutes : user.arrivalMinutes;
    final candidateTime = useDeparture
        ? candidate.departureMinutes
        : candidate.arrivalMinutes;
    final difference = (userTime - candidateTime).abs();
    final score = switch (difference) {
      <= 15 => 25,
      <= 30 => 20,
      <= 45 => 14,
      <= 60 => 8,
      _ => 0,
    };
    if (difference <= 15) {
      reasons.add(
        '${useDeparture ? 'Departure' : 'Arrival'} times are within 15 minutes',
      );
    } else if (difference <= 45) {
      reasons.add('Preferred times are within 45 minutes');
    }
    return score;
  }

  bool _rolesCompatible(CommuterProfile user, CommuterProfile candidate) {
    final candidateCanTakeUser =
        user.role.canRide &&
        candidate.role.canDrive &&
        candidate.availableSeats > 0;
    final userCanTakeCandidate = user.role.canDrive && candidate.role.canRide;
    return candidateCanTakeUser || userCanTakeCandidate;
  }
}
