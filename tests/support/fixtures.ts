import { test as base } from 'playwright-bdd'; // v9: los fixtures custom extienden el test de playwright-bdd
import { expect, type APIResponse, type Page, type APIRequestContext } from '@playwright/test';
import { createBdd } from 'playwright-bdd';
import { RegistrationPage } from '../pages/registration.page';
import { generateTestUser, type TestUser } from './test-data';

export interface ApiState {
  response?: APIResponse;
  json?: unknown;
}

export interface TestFixtures {
  registrationPage: RegistrationPage;
  testUser: TestUser;
  existingUser: TestUser;
  apiState: ApiState;
}

export const test = base.extend<TestFixtures>({
  // POM disponible en todos los pasos BDD; navega a la raíz de la app antes de cada escenario
  registrationPage: async ({ page }: { page: Page }, use) => {
    const pageObject = new RegistrationPage(page);
    await pageObject.goto();
    await use(pageObject);
  },

  // Dato dinámico único por escenario (faker + runId de la ejecución)
  testUser: async ({}, use) => {
    await use(generateTestUser());
  },

  // Usuario ya persistido vía API: para escenarios que necesitan datos preexistentes
  existingUser: async ({ request }: { request: APIRequestContext }, use) => {
    const user = generateTestUser();
    const response = await request.post('/api/users', { data: user });
    if (response.status() !== 201) {
      throw new Error(`No se pudo sembrar el usuario existente: ${response.status()}`);
    }
    await use(user);
  },

  apiState: async ({}, use) => {
    await use({});
  },
});

export const { Given, When, Then } = createBdd(test);
export { expect };
