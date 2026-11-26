/** Returns true when a notification should be deferred because quiet hours are active. */
export function isInQuietHours(
  now: Date,
  quietHoursStart: number | null | undefined,
  quietHoursEnd: number | null | undefined,
): boolean {
  if (quietHoursStart == null || quietHoursEnd == null) return false;
  const minute = now.getUTCHours() * 60 + now.getUTCMinutes();
  if (quietHoursStart === quietHoursEnd) return true;
  if (quietHoursStart < quietHoursEnd) {
    return minute >= quietHoursStart && minute < quietHoursEnd;
  }
  // Overnight quiet hours, e.g. 22:00-07:00
  return minute >= quietHoursStart || minute < quietHoursEnd;
}
