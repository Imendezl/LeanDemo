import type { Locator, Page } from '@playwright/test';
import type { TestUser } from '../support/test-data';

// Semantic mapping (Gherkin field names) → DOM testids.
// Locators live ONCE here: if the frontend changes, only this POM is touched.
const FIELD_SELECTORS: Record<string, string> = {
  name: 'field-name',
  email: 'field-email',
  password: 'field-password',
  country: 'field-country',
  birthdate: 'field-birthdate',
  terms: 'field-terms',
};

const FIELD_ERROR_IDS: Record<string, string> = {
  name: 'fullName',
  email: 'email',
  password: 'password',
  country: 'country',
  terms: 'acceptTerms',
};

const REQUIRED_FIELDS = ['fullName', 'email', 'password', 'country', 'acceptTerms'] as const;

export class RegistrationPage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  async goto(): Promise<void> {
    await this.page.goto('/');
    await this.page.getByTestId('registration-form').waitFor({ state: 'visible' });
  }

  async fillForm(user: TestUser): Promise<void> {
    await this.fillField('name', user.fullName);
    await this.fillField('email', user.email);
    await this.fillField('password', user.password);
    await this.page.getByTestId('field-country').selectOption({ label: user.country });
    if (user.birthdate) await this.fillField('birthdate', user.birthdate);
    await this.setTerms(user.acceptTerms);
  }

  async fillFormWithCountry(user: TestUser, country: string): Promise<void> {
    await this.fillForm({ ...user, country });
  }

  async fillField(alias: string, value: string): Promise<void> {
    const testId = FIELD_SELECTORS[alias] ?? alias;
    const control = this.page.getByTestId(testId);
    if (await control.evaluate((el) => el.tagName === 'INPUT' && (el as HTMLInputElement).type === 'checkbox')) {
      await control.setChecked(value === 'true');
    } else {
      await control.fill(value);
    }
  }

  async setTerms(accepted: boolean): Promise<void> {
    await this.page.getByTestId('field-terms').setChecked(accepted);
  }

  async submit(): Promise<void> {
    await this.page.getByTestId('button-submit').click();
  }

  successPanel(): Locator {
    return this.page.getByTestId('success-panel');
  }

  successMessage(): Locator {
    return this.page.getByTestId('success-message');
  }

  fieldError(alias: string): Locator {
    const fieldId = FIELD_ERROR_IDS[alias] ?? alias;
    return this.page.getByTestId(`error-${fieldId}`);
  }

  async expectAllRequiredFieldErrors(): Promise<void> {
    for (const field of REQUIRED_FIELDS) {
      await this.page.getByTestId(`error-${field}`).waitFor({ state: 'visible', timeout: 5_000 });
    }
  }
}
