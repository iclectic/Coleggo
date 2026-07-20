const developmentJwtSecret = 'dev-secret-change-in-production';

export interface RuntimeConfig {
  corsOrigin: string;
  jwtSecret: string;
}

export function getRuntimeConfig(environment = process.env): RuntimeConfig {
  const isProduction = environment.NODE_ENV === 'production';
  const jwtSecret = environment.JWT_SECRET ?? developmentJwtSecret;

  if (
    isProduction &&
    (jwtSecret === developmentJwtSecret || jwtSecret.length < 32)
  ) {
    throw new Error('JWT_SECRET must be a unique value of at least 32 characters in production.');
  }

  const corsOrigin = environment.CORS_ORIGIN ?? (isProduction ? '' : '*');
  if (isProduction && !corsOrigin) {
    throw new Error('CORS_ORIGIN must be configured in production.');
  }

  return { corsOrigin, jwtSecret };
}
