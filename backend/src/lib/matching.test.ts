import { rankMatches, scoreMatch, type MatchProfile } from './matching';

const base: MatchProfile = {
  id: 'u1',
  firstName: 'Alex',
  initials: 'AL',
  role: 'passenger',
  worksiteId: 'ws1',
  homeArea: 'Solihull',
  corridor: 'Solihull to city centre',
  days: [1, 3, 5],
  arrivalMinutes: 510,
  departureMinutes: 1050,
  availableSeats: 0,
};

const driver: MatchProfile = {
  ...base,
  id: 'u2',
  firstName: 'Asha',
  initials: 'AS',
  role: 'driver',
  availableSeats: 3,
};

describe('matching service', () => {
  it('scores a strong same-corridor worksite match', () => {
    const result = scoreMatch(base, driver);
    expect(result.isEligible).toBe(true);
    expect(result.score).toBeGreaterThanOrEqual(70);
    expect(result.breakdown.worksite).toBe(25);
    expect(result.positiveReasons.some((reason) => reason.type === 'worksite')).toBe(true);
  });

  it('marks different worksites as ineligible', () => {
    const result = scoreMatch(base, { ...driver, worksiteId: 'other' });
    expect(result.isEligible).toBe(false);
    expect(result.level).toBe('limited');
  });

  it('ranks eligible matches only', () => {
    const ranked = rankMatches(base, [
      driver,
      { ...driver, id: 'u3', firstName: 'Ben', worksiteId: 'other' },
    ]);
    expect(ranked).toHaveLength(1);
    expect(ranked[0].profile.id).toBe('u2');
  });
});
