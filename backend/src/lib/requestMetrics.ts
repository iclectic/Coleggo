export interface RequestSample {
  at: number;
  path: string;
  method: string;
  status: number;
  latencyMs: number;
}

const MAX_SAMPLES = 2000;
const samples: RequestSample[] = [];

export function recordRequestSample(sample: RequestSample) {
  samples.push(sample);
  if (samples.length > MAX_SAMPLES) {
    samples.splice(0, samples.length - MAX_SAMPLES);
  }
}

export function getSloSnapshot(windowMs = 15 * 60 * 1000) {
  const cutoff = Date.now() - windowMs;
  const recent = samples.filter((sample) => sample.at >= cutoff);
  const total = recent.length;
  const errors = recent.filter((sample) => sample.status >= 500).length;
  const latencies = recent.map((sample) => sample.latencyMs).sort((a, b) => a - b);
  const p95 = latencies.length === 0
    ? 0
    : latencies[Math.min(latencies.length - 1, Math.floor(latencies.length * 0.95))];
  return {
    windowMs,
    requestCount: total,
    errorCount: errors,
    errorRate: total === 0 ? 0 : errors / total,
    p95LatencyMs: p95,
    samplesRetained: samples.length,
  };
}

export function resetRequestSamples() {
  samples.length = 0;
}
