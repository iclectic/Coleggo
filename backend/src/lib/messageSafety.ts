const riskyPatterns = [
  /\b\d{10,}\b/,
  /\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b/,
  /\b[A-Z]{1,2}\d{1,2}\s?\d[A-Z]{2}\b/i, // UK-style postcode-ish
  /\b(my (home|house|flat) address|come to my (house|flat)|exact address)\b/i,
];

export function assessMessageBody(body: string): 'stored' | 'flagged' {
  const trimmed = body.trim();
  if (!trimmed) return 'flagged';
  if (riskyPatterns.some((pattern) => pattern.test(trimmed))) return 'flagged';
  return 'stored';
}
