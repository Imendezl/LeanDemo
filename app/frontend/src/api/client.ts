import type { RegistrationData } from '../lib/validation';

export interface CreatedUser {
  id: string;
  fullName: string;
  email: string;
  country: string;
}

export type RegisterResult =
  | { ok: true; user: CreatedUser }
  | { ok: false; status: number; errors: Record<string, string> };

export async function registerUser(data: RegistrationData): Promise<RegisterResult> {
  const response = await fetch('/api/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });

  if (response.status === 201) {
    return { ok: true, user: await response.json() };
  }

  const body = await response.json().catch(() => ({ errors: {} }));
  const errors = body.errors ?? {};
  // El backend responde 409 para correos duplicados: se muestra como error de campo.
  if (response.status === 409 && !errors.email) {
    errors.email = body.message ?? 'El correo electrónico ya está registrado';
  }
  return { ok: false, status: response.status, errors };
}
