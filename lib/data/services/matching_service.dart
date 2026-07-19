import '../mock/mock_data.dart';
import '../models/commuter_profile.dart';
import '../models/match_result.dart';
import '../models/shift_pattern.dart';

abstract interface class CommuteMatchingService {
  CommuteMatchResult calculate({
    required CommuterProfile currentUser,
    required CommuterProfile candidate,
  });
}

typedef CommuteMatchResult = MatchResult;

class MatchingService implements CommuteMatchingService {
  const MatchingService();

  List<MatchResult> findMatches(
    CommuterProfile user,
    Iterable<CommuterProfile> candidates,
  ) {
    final matches = candidates
        .where((candidate) => candidate.id != user.id)
        .map((candidate) => calculate(currentUser: user, candidate: candidate))
        .where((match) => match.isEligible && match.score >= 55)
        .toList();
    matches.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      return scoreOrder != 0
          ? scoreOrder
          : a.profile.firstName.compareTo(b.profile.firstName);
    });
    return matches;
  }

  @override
  MatchResult calculate({
    required CommuterProfile currentUser,
    required CommuterProfile candidate,
  }) => score(currentUser, candidate);

  MatchResult score(CommuterProfile user, CommuterProfile candidate) {
    final positives = <MatchReason>[];
    final limitations = <MatchReason>[];
    final worksite = _worksiteScore(user, candidate, positives, limitations);
    final area = _areaScore(user, candidate, positives, limitations);
    final time = _timeScore(user, candidate, positives, limitations);

    final sharedDays = user.days.intersection(candidate.days).length;
    final days = user.days.isEmpty
        ? 0
        : (15 * sharedDays / user.days.length).round();
    if (sharedDays > 0) {
      positives.add(
        MatchReason(
          type: MatchReasonType.days,
          message:
              '$sharedDays matching commute ${sharedDays == 1 ? 'day' : 'days'}',
        ),
      );
    } else {
      limitations.add(
        const MatchReason(
          type: MatchReasonType.days,
          message: 'No matching commute days yet',
        ),
      );
    }

    final role = _rolesCompatible(user, candidate) ? 10 : 0;
    if (role > 0) {
      positives.add(
        const MatchReason(
          type: MatchReasonType.role,
          message: 'Driver and passenger roles are compatible',
        ),
      );
    } else {
      limitations.add(
        const MatchReason(
          type: MatchReasonType.role,
          message: 'Both commuters need the same role for this journey',
        ),
      );
    }

    final seats = _seatScore(user, candidate, positives, limitations);
    final recurring = user.days.intersection(candidate.days).length >= 2
        ? 5
        : 0;
    if (recurring > 0) {
      positives.add(
        const MatchReason(
          type: MatchReasonType.recurring,
          message: 'Enough shared days for a recurring arrangement',
        ),
      );
    } else {
      limitations.add(
        const MatchReason(
          type: MatchReasonType.recurring,
          message: 'Shared schedule may only support occasional journeys',
        ),
      );
    }

    if (candidate.role.canDrive && candidate.availableSeats > 0) {
      positives.add(
        MatchReason(
          type: MatchReasonType.seats,
          message:
              '${candidate.availableSeats} ${candidate.availableSeats == 1 ? 'seat' : 'seats'} available',
        ),
      );
    }

    final breakdown = MatchBreakdown(
      worksite: worksite,
      area: area,
      time: time,
      days: days,
      role: role,
      seats: seats,
      recurring: recurring,
    );
    final score = breakdown.total.clamp(0, 100);
    final eligible = worksite > 0 && role > 0 && time > 0 && sharedDays > 0;
    return MatchResult(
      profile: candidate,
      score: score,
      level: eligible ? _levelFor(score) : MatchLevel.limited,
      breakdown: breakdown,
      positiveReasons: positives,
      limitations: limitations,
      isEligible: eligible,
    );
  }

  int _worksiteScore(
    CommuterProfile user,
    CommuterProfile candidate,
    List<MatchReason> positives,
    List<MatchReason> limitations,
  ) {
    if (user.worksiteId == candidate.worksiteId) {
      positives.add(
        const MatchReason(
          type: MatchReasonType.worksite,
          message: 'Same verified worksite',
        ),
      );
      return 25;
    }
    limitations.add(
      const MatchReason(
        type: MatchReasonType.worksite,
        message: 'Different worksites, so the commute may not align',
      ),
    );
    return 0;
  }

  int _areaScore(
    CommuterProfile user,
    CommuterProfile candidate,
    List<MatchReason> positives,
    List<MatchReason> limitations,
  ) {
    if (user.homeArea == candidate.homeArea) {
      positives.add(
        const MatchReason(
          type: MatchReasonType.area,
          message: 'Starts from the same approximate area',
          estimated: true,
        ),
      );
      return 20;
    }
    if (user.corridor == candidate.corridor) {
      positives.add(
        const MatchReason(
          type: MatchReasonType.area,
          message: 'Nearby area on the same broad corridor',
          estimated: true,
        ),
      );
      return 16;
    }
    final userDirection = MockData.areaCorridors[user.homeArea]
        ?.split(' to ')
        .first;
    final candidateDirection = MockData.areaCorridors[candidate.homeArea]
        ?.split(' to ')
        .first;
    if (userDirection != null && userDirection == candidateDirection) {
      positives.add(
        const MatchReason(
          type: MatchReasonType.area,
          message: 'Related journey corridor',
          estimated: true,
        ),
      );
      return 10;
    }
    limitations.add(
      const MatchReason(
        type: MatchReasonType.area,
        message: 'Starting areas may require a moderate detour',
        estimated: true,
      ),
    );
    return 4;
  }

  int _timeScore(
    CommuterProfile user,
    CommuterProfile candidate,
    List<MatchReason> positives,
    List<MatchReason> limitations,
  ) {
    final userShift = user.shiftPattern ?? _patternFromProfile(user);
    final candidateShift =
        candidate.shiftPattern ?? _patternFromProfile(candidate);
    if (!userShift.overlapsWith(candidateShift)) {
      limitations.add(
        const MatchReason(
          type: MatchReasonType.time,
          message: 'Shift windows do not overlap',
        ),
      );
      return 0;
    }
    final arrivalDifference = _cyclicDifference(
      userShift.startMinutes,
      candidateShift.startMinutes,
    );
    final departureDifference = _cyclicDifference(
      userShift.endMinutes,
      candidateShift.endMinutes,
    );
    final difference = arrivalDifference <= departureDifference
        ? arrivalDifference
        : departureDifference;
    final score = switch (difference) {
      <= 15 => 20,
      <= 30 => 16,
      <= 45 => 11,
      <= 60 => 6,
      _ => 0,
    };
    if (difference <= 15) {
      positives.add(
        const MatchReason(
          type: MatchReasonType.time,
          message: 'Shift times are within 15 minutes',
        ),
      );
    } else if (difference <= 45) {
      positives.add(
        const MatchReason(
          type: MatchReasonType.time,
          message: 'Shift times are within 45 minutes',
        ),
      );
    } else {
      limitations.add(
        const MatchReason(
          type: MatchReasonType.time,
          message: 'Shift times differ by more than 45 minutes',
        ),
      );
    }
    return score;
  }

  int _seatScore(
    CommuterProfile user,
    CommuterProfile candidate,
    List<MatchReason> positives,
    List<MatchReason> limitations,
  ) {
    final driver = candidate.role.canDrive ? candidate : user;
    if (!driver.role.canDrive) return 0;
    if (driver.availableSeats > 0) return 5;
    limitations.add(
      const MatchReason(
        type: MatchReasonType.seats,
        message: 'No seats are currently available',
      ),
    );
    return 0;
  }

  bool _rolesCompatible(CommuterProfile user, CommuterProfile candidate) {
    final candidateCanTakeUser =
        user.role.canRide &&
        candidate.role.canDrive &&
        candidate.availableSeats > 0;
    final userCanTakeCandidate = user.role.canDrive && candidate.role.canRide;
    return candidateCanTakeUser || userCanTakeCandidate;
  }

  ShiftPattern _patternFromProfile(CommuterProfile profile) => ShiftPattern(
    id: '${profile.id}-commute',
    name: 'Commute pattern',
    kind: ShiftKind.custom,
    startMinutes: profile.arrivalMinutes,
    endMinutes: profile.departureMinutes,
    arrivalBufferMinutes: 15,
    departureWindowStartMinutes: profile.departureMinutes - 10,
    departureWindowEndMinutes: profile.departureMinutes + 10,
    recurringDays: profile.days,
    dayType: profile.arrivalMinutes > profile.departureMinutes
        ? ShiftDayType.night
        : ShiftDayType.day,
  );

  int _cyclicDifference(int a, int b) {
    const minutesPerDay = 24 * 60;
    final direct = (a - b).abs();
    return direct > minutesPerDay / 2 ? minutesPerDay - direct : direct;
  }

  MatchLevel _levelFor(int score) => switch (score) {
    >= 85 => MatchLevel.excellent,
    >= 70 => MatchLevel.strong,
    >= 55 => MatchLevel.possible,
    _ => MatchLevel.limited,
  };
}
