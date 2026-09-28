import { When, Then, expect } from '../support/fixtures';
import type { TestUser } from '../support/test-data';

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

// --- Actions ---

When('I check the service health', async ({ request, apiState }) => {
  apiState.response = await request.get('/api/health');
  apiState.json = await apiState.response.json();
});

When('I create the user through the API', async ({ request, apiState, testUser }) => {
  apiState.response = await request.post('/api/users', { data: testUser });
  apiState.json = await apiState.response.json().catch(() => undefined);
});

When('I create the existing user again through the API', async ({ request, apiState, existingUser }) => {
  apiState.response = await request.post('/api/users', { data: existingUser });
  apiState.json = await apiState.response.json().catch(() => undefined);
});

When('I create a user through the API without the {string} field', async ({ request, apiState, testUser }, field: string) => {
  const { [field as keyof TestUser]: _omitted, ...incomplete } = testUser;
  apiState.response = await request.post('/api/users', { data: incomplete });
  apiState.json = await apiState.response.json().catch(() => undefined);
});

When('I fetch the users list', async ({ request, apiState }) => {
  apiState.response = await request.get('/api/users');
  apiState.json = await apiState.response.json();
});

// --- Assertions ---

Then('the response has status code {int}', async ({ apiState }, statusCode: number) => {
  expect(apiState.response, 'No previous response: a When step is missing').toBeDefined();
  expect(apiState.response!.status()).toBe(statusCode);
});

Then('the reported status is {string}', async ({ apiState }, status: string) => {
  expect(isRecord(apiState.json) && apiState.json.status).toBe(status);
});

Then('the created user matches the generated data', async ({ apiState, testUser }) => {
  expect(isRecord(apiState.json)).toBeTruthy();
  const user = apiState.json as Record<string, unknown>;
  expect(user.email).toBe(testUser.email);
  expect(user.fullName).toBe(testUser.fullName);
  expect(user.country).toBe(testUser.country);
  expect(user.password).toBeUndefined(); // the API never returns the password
  expect(user.id).toBeTruthy();
});

Then('the response contains the error {string}', async ({ apiState }, message: string) => {
  const errors = isRecord(apiState.json) && isRecord(apiState.json.errors) ? apiState.json.errors : {};
  const messages = [...Object.values(errors), isRecord(apiState.json) ? apiState.json.message : '']
    .filter((v): v is string => typeof v === 'string');
  expect(messages).toContain(message);
});

Then('the response contains the validation error for {string}', async ({ apiState }, field: string) => {
  expect(isRecord(apiState.json) && isRecord(apiState.json.errors)).toBeTruthy();
  const errors = (apiState.json as Record<string, unknown>).errors as Record<string, string>;
  expect(errors[field], `Expected a validation error for field "${field}"`).toBeTruthy();
});

Then('the users list includes the generated user', async ({ apiState, testUser }) => {
  expect(isRecord(apiState.json)).toBeTruthy();
  const users = (apiState.json as Record<string, unknown>).users;
  expect(Array.isArray(users)).toBeTruthy();
  expect((users as Array<{ email: string }>).some((u) => u.email === testUser.email)).toBeTruthy();
});
