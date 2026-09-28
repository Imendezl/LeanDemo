import { describe, expect, it } from 'vitest';
import { validateRegistration, VALIDATION_MESSAGES } from './validation';

const validUser = {
  fullName: 'Ada Lovelace',
  email: 'ada@example.com',
  password: 'analitica1843',
  country: 'España',
  birthdate: '1815-12-10',
  acceptTerms: true,
};

describe('validateRegistration', () => {
  it('acepta un registro con todos los datos correctos', () => {
    expect(validateRegistration(validUser)).toEqual({});
  });

  it('rechaza un nombre demasiado corto', () => {
    expect(validateRegistration({ ...validUser, fullName: 'A' }).fullName)
      .toBe(VALIDATION_MESSAGES.fullName);
  });

  it('rechaza un correo con formato inválido', () => {
    for (const email of ['sin-arroba', 'a@b', 'a b@c.com', '']) {
      expect(validateRegistration({ ...validUser, email }).email)
        .toBe(VALIDATION_MESSAGES.email);
    }
  });

  it('rechaza contraseñas débiles', () => {
    for (const password of ['corta1', 'sinnumeros', '12345678', '']) {
      expect(validateRegistration({ ...validUser, password }).password)
        .toBe(VALIDATION_MESSAGES.password);
    }
  });

  it('exige seleccionar un país', () => {
    expect(validateRegistration({ ...validUser, country: '' }).country)
      .toBe(VALIDATION_MESSAGES.country);
  });

  it('exige aceptar los términos y condiciones', () => {
    expect(validateRegistration({ ...validUser, acceptTerms: false }).acceptTerms)
      .toBe(VALIDATION_MESSAGES.acceptTerms);
  });

  it('acumula todos los errores cuando el formulario está vacío', () => {
    const errors = validateRegistration({});
    expect(Object.keys(errors)).toEqual(
      expect.arrayContaining(['fullName', 'email', 'password', 'country', 'acceptTerms']),
    );
  });
});
