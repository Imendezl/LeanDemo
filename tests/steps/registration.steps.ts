import { When, Then, Given, expect } from '../support/fixtures';

// --- Background ---

Given('the registration application is available', async ({ request, registrationPage }) => {
  const response = await request.get('/api/health');
  expect(response.ok()).toBeTruthy();
  await expect(registrationPage.page).toHaveTitle(/Registro/);
});

// --- Dynamic test data ---

Given('I generate random test data for a new user', async ({ testUser }) => {
  expect(testUser.email).toMatch(/@ejemplo\.test$/);
});

Given('a user with dynamic data is already registered', async ({ existingUser }) => {
  // The existingUser fixture seeds the user via the API before the scenario
  expect(existingUser.email).toMatch(/@ejemplo\.test$/);
});

// --- Form actions ---

When('I fill the registration form with the generated data', async ({ registrationPage, testUser }) => {
  await registrationPage.fillForm(testUser);
});

When(
  'I fill the registration form with the generated data and country {string}',
  async ({ registrationPage, testUser }, country: string) => {
    await registrationPage.fillFormWithCountry(testUser, country);
  },
);

When('I fill the registration form with the existing user\'s email', async ({ registrationPage, testUser, existingUser }) => {
  await registrationPage.fillForm({ ...testUser, email: existingUser.email });
});

When('I type {string} into the {string} field', async ({ registrationPage }, value: string, field: string) => {
  await registrationPage.fillField(field, value);
});

When('I uncheck the terms and conditions checkbox', async ({ registrationPage }) => {
  await registrationPage.setTerms(false);
});

When('I submit the form', async ({ registrationPage }) => {
  await registrationPage.submit();
});

When('I submit an empty form', async ({ registrationPage }) => {
  await registrationPage.submit();
});

// --- Assertions ---

Then('I see the successful registration message', async ({ registrationPage }) => {
  const panel = registrationPage.successPanel();
  await expect(panel).toBeVisible();
  await expect(panel).toContainText(/registro exitoso/i);
});

Then('the user is stored in the system', async ({ request, testUser }) => {
  const response = await request.get('/api/users');
  expect(response.ok()).toBeTruthy();
  const body = await response.json();
  const emails = body.users.map((u: { email: string }) => u.email);
  expect(emails).toContain(testUser.email);
});

Then('I see the validation errors for all required fields', async ({ registrationPage }) => {
  await registrationPage.expectAllRequiredFieldErrors();
});

Then(
  'I see the validation error {string} in the {string} field',
  async ({ registrationPage }, message: string, field: string) => {
    const error = registrationPage.fieldError(field);
    await expect(error).toBeVisible();
    await expect(error).toHaveText(message);
  },
);

Then('I do not see the successful registration message', async ({ registrationPage }) => {
  await expect(registrationPage.successPanel()).toHaveCount(0);
});
