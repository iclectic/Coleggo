import { buildCapacityHints } from './capacityHints';

describe('capacityHints', () => {
  it('flags under-served corridor weekdays for organisers', () => {
    const hints = buildCapacityHints({
      profiles: [
        { corridor: 'Solihull to city centre', days: [2, 4] },
        { corridor: 'Solihull to city centre', days: [2, 4] },
        { corridor: 'Solihull to city centre', days: [1] },
      ],
      circles: [
        { corridorHint: 'Solihull to city centre', days: [1, 3, 5], seats: 2 },
      ],
    });
    expect(hints).toHaveLength(1);
    expect(hints[0].underServedDays).toEqual([2, 4]);
    expect(hints[0].message).toContain('Tue/Thu');
  });
});
