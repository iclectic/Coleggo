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

  it('scores approximate postcode districts without exact home coordinates', () => {
    const nearby = scoreMatch(
      { ...base, homeArea: 'Sparkbrook', postcodeDistrict: 'B11' },
      { ...driver, homeArea: 'Balsall Heath', postcodeDistrict: 'B11' },
    );
    expect(nearby.breakdown.area).toBe(20);
    expect(nearby.positiveReasons.some((reason) => reason.message.includes('postcode'))).toBe(true);
  });

  it('scores nearby approximate corridor centres', () => {
    const nearby = scoreMatch(
      {
        ...base,
        homeArea: 'A',
        corridor: 'other corridor',
        approxLatitude: 52.48,
        approxLongitude: -1.89,
      },
      {
        ...driver,
        homeArea: 'B',
        corridor: 'different corridor',
        approxLatitude: 52.481,
        approxLongitude: -1.891,
      },
    );
    expect(nearby.breakdown.area).toBe(18);
  });
});
