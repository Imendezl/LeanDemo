import { faker } from '@faker-js/faker/locale/es';
import { COUNTRIES } from '../../app/frontend/src/lib/validation';

// Datos de prueba DINÁMICOS: cada ejecución genera usuarios únicos (faker + runId),
// de modo que los entornos efímeros nunca dependen de datos sembrados a mano
// y las ejecuciones son repetibles y aisladas entre sí.

export interface TestUser {
  fullName: string;
  email: string;
  password: string;
  country: string;
  birthdate: string;
  acceptTerms: boolean;
}

/** Identificador de la ejecución: agrupa todos los datos generados en esta corrida. */
export const RUN_ID = `${new Date().toISOString().slice(0, 10).replaceAll('-', '')}-${Math.random().toString(36).slice(2, 8)}`;

export function generateTestUser(overrides: Partial<TestUser> = {}): TestUser {
  const firstName = faker.person.firstName();
  const lastName = faker.person.lastName();

  return {
    fullName: `${firstName} ${lastName}`,
    email: `qa.${RUN_ID}.${faker.string.alphanumeric(8).toLowerCase()}@ejemplo.test`,
    // Cumple la política: 8+ caracteres con letras y números
    password: `Qa${faker.string.alphanumeric(8)}7x`,
    country: faker.helpers.arrayElement(COUNTRIES),
    birthdate: faker.date
      .birthdate({ min: 18, max: 65, mode: 'age' })
      .toISOString()
      .slice(0, 10),
    acceptTerms: true,
    ...overrides,
  };
}
