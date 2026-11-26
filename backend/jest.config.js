/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: 'ts-jest/presets/default',
  testEnvironment: 'node',
  testMatch: ['**/*.test.ts'],
  roots: ['<rootDir>/src'],
  moduleFileExtensions: ['ts', 'js'],
  // Integration suites share one Postgres database; parallel workers race on cleanup.
  maxWorkers: 1,
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts', '!src/index.ts'],
};
