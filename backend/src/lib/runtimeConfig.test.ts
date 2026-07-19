import { getRuntimeConfig } from './runtimeConfig';

describe('getRuntimeConfig', () => {
  it('uses development defaults outside production', () => {
    expect(getRuntimeConfig({ NODE_ENV: 'development' })).toEqual({
      corsOrigin: '*',
      jwtSecret: 'dev-secret-change-in-production',
    });
  });

  it('rejects the development JWT secret in production', () => {
    expect(() => getRuntimeConfig({ NODE_ENV: 'production' })).toThrow(
      'JWT_SECRET must be a unique value of at least 32 characters in production.',
    );
  });

  it('requires a CORS origin in production', () => {
    expect(() =>
      getRuntimeConfig({
        NODE_ENV: 'production',
        JWT_SECRET: 'a-secure-production-secret-with-32-chars',
      }),
    ).toThrow('CORS_ORIGIN must be configured in production.');
  });

  it('returns valid production settings', () => {
    expect(
      getRuntimeConfig({
        NODE_ENV: 'production',
        JWT_SECRET: 'a-secure-production-secret-with-32-chars',
        CORS_ORIGIN: 'https://staging.example.com',
      }),
    ).toEqual({
      corsOrigin: 'https://staging.example.com',
      jwtSecret: 'a-secure-production-secret-with-32-chars',
    });
  });
});
