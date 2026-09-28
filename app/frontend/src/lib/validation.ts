// Contrato de validación compartido conceptualmente con el backend (app/backend/src/app.js).
// Los mensajes son idénticos en ambas capas: la suite BDD los usa como especificación ejecutable.

export interface RegistrationData {
  fullName: string;
  email: string;
  password: string;
  country: string;
  birthdate: string;
  acceptTerms: boolean;
}

export const VALIDATION_MESSAGES = {
  fullName: 'El nombre debe tener al menos 2 caracteres',
  email: 'Introduce un correo electrónico válido',
  password: 'La contraseña debe tener al menos 8 caracteres e incluir letras y números',
  country: 'Selecciona un país',
  acceptTerms: 'Debes aceptar los términos y condiciones',
  duplicateEmail: 'El correo electrónico ya está registrado',
} as const;

export type FieldErrors = Partial<Record<'fullName' | 'email' | 'password' | 'country' | 'acceptTerms', string>>;

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const PASSWORD_RE = /^(?=.*[A-Za-z])(?=.*\d).{8,}$/;

export function validateRegistration(data: Partial<RegistrationData>): FieldErrors {
  const errors: FieldErrors = {};

  if ((data.fullName ?? '').trim().length < 2) errors.fullName = VALIDATION_MESSAGES.fullName;
  if (!EMAIL_RE.test((data.email ?? '').trim())) errors.email = VALIDATION_MESSAGES.email;
  if (!PASSWORD_RE.test(data.password ?? '')) errors.password = VALIDATION_MESSAGES.password;
  if (!data.country) errors.country = VALIDATION_MESSAGES.country;
  if (data.acceptTerms !== true) errors.acceptTerms = VALIDATION_MESSAGES.acceptTerms;

  return errors;
}

export const COUNTRIES = [
  'España',
  'México',
  'Argentina',
  'Colombia',
  'Chile',
  'Perú',
  'Estados Unidos',
];
