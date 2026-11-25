export type MatchRole = 'driver' | 'passenger' | 'both';

export interface MatchProfile {
  id: string;
  firstName: string;
  initials: string;
  role: MatchRole;
  worksiteId: string;
  homeArea: string;
  corridor: string;
  days: number[];
  arrivalMinutes: number;
  departureMinutes: number;
  availableSeats: number;
  vehicleSummary?: string | null;
}

export interface MatchReason {
  type: 'worksite' | 'area' | 'time' | 'days' | 'role' | 'seats' | 'recurring';
  message: string;
  estimated?: boolean;
}

export interface MatchBreakdown {
  worksite: number;
  area: number;
  time: number;
  days: number;
  role: number;
  seats: number;
  recurring: number;
}

export interface MatchResultDto {
  profile: {
    id: string;
    firstName: string;
    initials: string;
    role: MatchRole;
    homeArea: string;
    corridor: string;
    days: number[];
    arrivalMinutes: number;
    departureMinutes: number;
    availableSeats: number;
    vehicleSummary?: string | null;
    worksiteId: string;
  };
  score: number;
  level: 'excellent' | 'strong' | 'possible' | 'limited';
  breakdown: MatchBreakdown;
  positiveReasons: MatchReason[];
  limitations: MatchReason[];
  isEligible: boolean;
  estimated: true;
}

function canDrive(role: MatchRole): boolean {
  return role === 'driver' || role === 'both';
}

function canRide(role: MatchRole): boolean {
  return role === 'passenger' || role === 'both';
}

function cyclicDifference(a: number, b: number): number {
  const minutesPerDay = 24 * 60;
  const direct = Math.abs(a - b);
  return direct > minutesPerDay / 2 ? minutesPerDay - direct : direct;
}

function shiftsOverlap(user: MatchProfile, candidate: MatchProfile): boolean {
  // Overnight-aware: treat intervals on a circular day clock using arrival/departure.
  const userStart = user.arrivalMinutes;
  const userEnd = user.departureMinutes;
  const candidateStart = candidate.arrivalMinutes;
  const candidateEnd = candidate.departureMinutes;
  const userOvernight = userStart > userEnd;
  const candidateOvernight = candidateStart > candidateEnd;
  if (!userOvernight && !candidateOvernight) {
    return userStart <= candidateEnd && candidateStart <= userEnd;
  }
  // Conservative overnight overlap: any shared day-window proximity counts.
  return cyclicDifference(userStart, candidateStart) <= 90
    || cyclicDifference(userEnd, candidateEnd) <= 90;
}

function levelFor(score: number, eligible: boolean): MatchResultDto['level'] {
  if (!eligible) return 'limited';
  if (score >= 85) return 'excellent';
  if (score >= 70) return 'strong';
  if (score >= 55) return 'possible';
  return 'limited';
}

export function scoreMatch(user: MatchProfile, candidate: MatchProfile): MatchResultDto {
  const positives: MatchReason[] = [];
  const limitations: MatchReason[] = [];

  let worksite = 0;
  if (user.worksiteId === candidate.worksiteId) {
    worksite = 25;
    positives.push({ type: 'worksite', message: 'Same verified worksite' });
  } else {
    limitations.push({
      type: 'worksite',
      message: 'Different worksites, so the commute may not align',
    });
  }

  let area = 4;
  if (user.homeArea === candidate.homeArea) {
    area = 20;
    positives.push({
      type: 'area',
      message: 'Starts from the same approximate area',
      estimated: true,
    });
  } else if (user.corridor === candidate.corridor) {
    area = 16;
    positives.push({
      type: 'area',
      message: 'Nearby area on the same broad corridor',
      estimated: true,
    });
  } else {
    limitations.push({
      type: 'area',
      message: 'Starting areas may require a moderate detour',
      estimated: true,
    });
  }

  let time = 0;
  if (!shiftsOverlap(user, candidate)) {
    limitations.push({ type: 'time', message: 'Shift windows do not overlap' });
  } else {
    const arrivalDifference = cyclicDifference(user.arrivalMinutes, candidate.arrivalMinutes);
    const departureDifference = cyclicDifference(user.departureMinutes, candidate.departureMinutes);
    const difference = Math.min(arrivalDifference, departureDifference);
    time = difference <= 15 ? 20
      : difference <= 30 ? 16
        : difference <= 45 ? 11
          : difference <= 60 ? 6
            : 0;
    if (difference <= 15) {
      positives.push({ type: 'time', message: 'Shift times are within 15 minutes' });
    } else if (difference <= 45) {
      positives.push({ type: 'time', message: 'Shift times are within 45 minutes' });
    } else {
      limitations.push({ type: 'time', message: 'Shift times differ by more than 45 minutes' });
    }
  }

  const sharedDays = user.days.filter((day) => candidate.days.includes(day)).length;
  const days = user.days.length === 0 ? 0 : Math.round((15 * sharedDays) / user.days.length);
  if (sharedDays > 0) {
    positives.push({
      type: 'days',
      message: `${sharedDays} matching commute ${sharedDays === 1 ? 'day' : 'days'}`,
    });
  } else {
    limitations.push({ type: 'days', message: 'No matching commute days yet' });
  }

  const candidateCanTakeUser = canRide(user.role) && canDrive(candidate.role) && candidate.availableSeats > 0;
  const userCanTakeCandidate = canDrive(user.role) && canRide(candidate.role);
  const rolesCompatible = candidateCanTakeUser || userCanTakeCandidate;
  const role = rolesCompatible ? 10 : 0;
  if (role > 0) {
    positives.push({
      type: 'role',
      message: 'Driver and passenger roles are compatible',
    });
  } else {
    limitations.push({
      type: 'role',
      message: 'Both commuters need the same role for this journey',
    });
  }

  const driver = canDrive(candidate.role) ? candidate : user;
  let seats = 0;
  if (canDrive(driver.role) && driver.availableSeats > 0) {
    seats = 5;
    if (canDrive(candidate.role) && candidate.availableSeats > 0) {
      positives.push({
        type: 'seats',
        message: `${candidate.availableSeats} ${candidate.availableSeats === 1 ? 'seat' : 'seats'} available`,
      });
    }
  } else if (canDrive(driver.role)) {
    limitations.push({ type: 'seats', message: 'No seats are currently available' });
  }

  const recurring = sharedDays >= 2 ? 5 : 0;
  if (recurring > 0) {
    positives.push({
      type: 'recurring',
      message: 'Enough shared days for a recurring arrangement',
    });
  } else {
    limitations.push({
      type: 'recurring',
      message: 'Shared schedule may only support occasional journeys',
    });
  }

  const breakdown: MatchBreakdown = {
    worksite,
    area,
    time,
    days,
    role,
    seats,
    recurring,
  };
  const score = Math.max(0, Math.min(100, Object.values(breakdown).reduce((sum, value) => sum + value, 0)));
  const isEligible = worksite > 0 && role > 0 && time > 0 && sharedDays > 0;

  return {
    profile: {
      id: candidate.id,
      firstName: candidate.firstName,
      initials: candidate.initials,
      role: candidate.role,
      homeArea: candidate.homeArea,
      corridor: candidate.corridor,
      days: candidate.days,
      arrivalMinutes: candidate.arrivalMinutes,
      departureMinutes: candidate.departureMinutes,
      availableSeats: candidate.availableSeats,
      vehicleSummary: candidate.vehicleSummary,
      worksiteId: candidate.worksiteId,
    },
    score,
    level: levelFor(score, isEligible),
    breakdown,
    positiveReasons: positives,
    limitations,
    isEligible,
    estimated: true,
  };
}

export function rankMatches(user: MatchProfile, candidates: MatchProfile[]): MatchResultDto[] {
  return candidates
    .filter((candidate) => candidate.id !== user.id)
    .map((candidate) => scoreMatch(user, candidate))
    .filter((match) => match.isEligible && match.score >= 55)
    .sort((a, b) => {
      const scoreOrder = b.score - a.score;
      return scoreOrder !== 0
        ? scoreOrder
        : a.profile.firstName.localeCompare(b.profile.firstName);
    });
}
