const DAY_LABELS: Record<number, string> = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

export interface CorridorDayDemand {
  corridor: string;
  day: number;
  demand: number;
  seatSupply: number;
}

export interface CapacityHint {
  corridor: string;
  underServedDays: number[];
  underServedLabels: string[];
  demand: number;
  seatSupply: number;
  message: string;
}

/**
 * Organiser-facing capacity hints: corridors where weekday demand exceeds
 * Circle seat supply. Never exposes individual home locations.
 */
export function buildCapacityHints(input: {
  profiles: Array<{ corridor: string; days: number[] }>;
  circles: Array<{ corridorHint?: string | null; days: number[]; seats: number }>;
  minGap?: number;
}): CapacityHint[] {
  const minGap = input.minGap ?? 1;
  const demand = new Map<string, number>();
  for (const profile of input.profiles) {
    for (const day of profile.days) {
      const key = `${profile.corridor}::${day}`;
      demand.set(key, (demand.get(key) ?? 0) + 1);
    }
  }

  const supply = new Map<string, number>();
  for (const circle of input.circles) {
    const corridor = circle.corridorHint;
    if (!corridor) continue;
    for (const day of circle.days) {
      const key = `${corridor}::${day}`;
      supply.set(key, (supply.get(key) ?? 0) + circle.seats);
    }
  }

  const byCorridor = new Map<string, { days: number[]; demand: number; seatSupply: number }>();
  for (const [key, dayDemand] of demand.entries()) {
    const [corridor, dayRaw] = key.split('::');
    const day = Number(dayRaw);
    const seatSupply = supply.get(key) ?? 0;
    if (dayDemand - seatSupply < minGap) continue;
    const existing = byCorridor.get(corridor) ?? { days: [], demand: 0, seatSupply: 0 };
    existing.days.push(day);
    existing.demand += dayDemand;
    existing.seatSupply += seatSupply;
    byCorridor.set(corridor, existing);
  }

  return [...byCorridor.entries()]
    .map(([corridor, value]) => {
      const underServedDays = value.days.sort((a, b) => a - b);
      const underServedLabels = underServedDays.map((day) => DAY_LABELS[day] ?? String(day));
      return {
        corridor,
        underServedDays,
        underServedLabels,
        demand: value.demand,
        seatSupply: value.seatSupply,
        message: `This corridor is under-served on ${underServedLabels.join('/')} nights`,
      };
    })
    .sort((a, b) => (b.demand - b.seatSupply) - (a.demand - a.seatSupply));
}
