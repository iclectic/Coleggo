import {
  emailMatchesWorkplace,
  isVerificationCurrent,
} from './workplaceAccess';

const workplace = {
  id: 'w1',
  name: 'Northstar',
  slug: 'northstar',
  domain: 'northstar.example',
  allowedDomains: ['northstar-contractors.example'],
  invitationCode: 'NORTH-PILOT',
  verificationValidDays: 90,
  createdAt: new Date(),
};

describe('workplaceAccess', () => {
  it('accepts primary and allowlisted domains', () => {
    expect(emailMatchesWorkplace('a@northstar.example', workplace)).toBe(true);
    expect(emailMatchesWorkplace('b@northstar-contractors.example', workplace)).toBe(true);
    expect(emailMatchesWorkplace('c@gmail.com', workplace)).toBe(false);
  });

  it('treats verification as current within the renewal window', () => {
    const verifiedAt = new Date();
    verifiedAt.setUTCDate(verifiedAt.getUTCDate() - 10);
    expect(
      isVerificationCurrent(
        { workplaceVerified: true, verifiedAt },
        workplace,
      ),
    ).toBe(true);
  });

  it('expires verification after the workplace validity window', () => {
    const verifiedAt = new Date();
    verifiedAt.setUTCDate(verifiedAt.getUTCDate() - 120);
    expect(
      isVerificationCurrent(
        { workplaceVerified: true, verifiedAt },
        workplace,
      ),
    ).toBe(false);
  });
});
