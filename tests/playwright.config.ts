import { defineConfig } from '@playwright/test';
import { defineBddConfig } from 'playwright-bdd';

const testDir = defineBddConfig({
  features: ['features/ui/*.feature', 'features/api/*.feature'],
  // support/fixtures.ts va incluido para que bddgen detecte la instancia `test` con fixtures custom
  steps: ['steps/**/*.ts', 'support/**/*.ts'],
  outputDir: '.features-gen',
});

// El entorno objetivo se inyecta por variable de entorno:
//   local:  BASE_URL=http://localhost:3000
//   Azure:  BASE_URL=https://app-qa-xxx.azurewebsites.net  (salida de Terraform)
// || (y no ??) para que una cadena vacía caiga también al valor local.
const baseURL = process.env.BASE_URL || 'http://localhost:3000';

export default defineConfig({
  testDir,
  outputDir: 'reports/test-results',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  // workers: 1 garantiza determinismo contra un backend con estado en memoria.
  // Al escalar a entornos con BD real, subir workers usando datos únicos por test.
  workers: process.env.CI ? 2 : 1,
  retries: process.env.CI ? 1 : 0,
  reporter: [
    ['list'],
    ['html', { outputFolder: 'reports/html', open: 'never' }],
    ['junit', { outputFile: 'reports/junit.xml' }],
  ],
  use: {
    baseURL,
    locale: 'es-ES',
    actionTimeout: 10_000,
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    trace: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
