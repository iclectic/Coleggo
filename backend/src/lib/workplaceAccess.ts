import { Profile, Workplace } from '@prisma/client';

export function allowedEmailDomains(workplace: Workplace): string[] {
  const domains = new Set<string>([
    workplace.domain.toLowerCase(),
    ...workplace.allowedDomains.map((domain) => domain.toLowerCase()),
  ]);
  return [...domains];
}

export function emailMatchesWorkplace(email: string, workplace: Workplace): boolean {
  const domain = email.split('@')[1]?.toLowerCase();
  if (!domain) return false;
  return allowedEmailDomains(workplace).includes(domain);
}

export function isVerificationCurrent(
  profile: Pick<Profile, 'workplaceVerified' | 'verifiedAt'>,
  workplace: Pick<Workplace, 'verificationValidDays'>,
  now = new Date(),
): boolean {
  if (!profile.workplaceVerified || !profile.verifiedAt) return false;
  const expiresAt = new Date(profile.verifiedAt);
  expiresAt.setUTCDate(expiresAt.getUTCDate() + workplace.verificationValidDays);
  return expiresAt.getTime() >= now.getTime();
}

export function verificationExpiresAt(
  verifiedAt: Date,
  verificationValidDays: number,
): Date {
  const expiresAt = new Date(verifiedAt);
  expiresAt.setUTCDate(expiresAt.getUTCDate() + verificationValidDays);
  return expiresAt;
}
