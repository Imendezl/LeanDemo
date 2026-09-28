import { useState } from 'react';
import { COUNTRIES, validateRegistration, type FieldErrors, type RegistrationData } from '../lib/validation';
import { registerUser, type CreatedUser } from '../api/client';

const EMPTY_FORM: RegistrationData = {
  fullName: '',
  email: '',
  password: '',
  country: '',
  birthdate: '',
  acceptTerms: false,
};

export function RegistrationForm() {
  const [form, setForm] = useState<RegistrationData>(EMPTY_FORM);
  const [errors, setErrors] = useState<FieldErrors>({});
  const [submitting, setSubmitting] = useState(false);
  const [created, setCreated] = useState<CreatedUser | null>(null);
  const [networkError, setNetworkError] = useState<string | null>(null);

  const update = <K extends keyof RegistrationData>(field: K, value: RegistrationData[K]) => {
    setForm((prev) => ({ ...prev, [field]: value }));
    setErrors((prev) => ({ ...prev, [field]: undefined }));
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setNetworkError(null);

    const clientErrors = validateRegistration(form);
    if (Object.keys(clientErrors).length > 0) {
      setErrors(clientErrors);
      return;
    }

    setSubmitting(true);
    try {
      const result = await registerUser(form);
      if (result.ok) {
        setCreated(result.user);
      } else {
        setErrors(result.errors as FieldErrors);
      }
    } catch {
      setNetworkError('No se pudo conectar con el servicio. Inténtalo de nuevo.');
    } finally {
      setSubmitting(false);
    }
  };

  if (created) {
    return (
      <div className="card" data-testid="success-panel">
        <h1>¡Registro exitoso!</h1>
        <p data-testid="success-message">
          Tu usuario se ha creado con el identificador <code>{created.id}</code>.
        </p>
        <p>
          Bienvenido/a, <strong>{created.fullName}</strong>. Hemos registrado{' '}
          <strong>{created.email}</strong>.
        </p>
        <button type="button" data-testid="button-new-registration" onClick={() => {
          setForm(EMPTY_FORM);
          setErrors({});
          setCreated(null);
        }}>
          Registrar otro usuario
        </button>
      </div>
    );
  }

  return (
    <form className="card" onSubmit={handleSubmit} noValidate data-testid="registration-form">
      <h1>Crear cuenta</h1>
      <p className="subtitle">Completa tus datos para registrarte</p>

      {networkError && (
        <p className="banner-error" data-testid="network-error" role="alert">
          {networkError}
        </p>
      )}

      <div className="field">
        <label htmlFor="fullName">Nombre completo</label>
        <input
          id="fullName"
          data-testid="field-name"
          type="text"
          value={form.fullName}
          onChange={(e) => update('fullName', e.target.value)}
          placeholder="Ada Lovelace"
        />
        {errors.fullName && <span className="error" data-testid="error-fullName">{errors.fullName}</span>}
      </div>

      <div className="field">
        <label htmlFor="email">Correo electrónico</label>
        <input
          id="email"
          data-testid="field-email"
          type="email"
          value={form.email}
          onChange={(e) => update('email', e.target.value)}
          placeholder="ada@ejemplo.com"
        />
        {errors.email && <span className="error" data-testid="error-email">{errors.email}</span>}
      </div>

      <div className="field">
        <label htmlFor="password">Contraseña</label>
        <input
          id="password"
          data-testid="field-password"
          type="password"
          value={form.password}
          onChange={(e) => update('password', e.target.value)}
          placeholder="Mínimo 8 caracteres, letras y números"
        />
        {errors.password && <span className="error" data-testid="error-password">{errors.password}</span>}
      </div>

      <div className="field-row">
        <div className="field">
          <label htmlFor="country">País</label>
          <select
            id="country"
            data-testid="field-country"
            value={form.country}
            onChange={(e) => update('country', e.target.value)}
          >
            <option value="">Selecciona…</option>
            {COUNTRIES.map((country) => (
              <option key={country} value={country}>{country}</option>
            ))}
          </select>
          {errors.country && <span className="error" data-testid="error-country">{errors.country}</span>}
        </div>

        <div className="field">
          <label htmlFor="birthdate">Fecha de nacimiento (opcional)</label>
          <input
            id="birthdate"
            data-testid="field-birthdate"
            type="date"
            value={form.birthdate}
            onChange={(e) => update('birthdate', e.target.value)}
          />
        </div>
      </div>

      <div className="field">
        <label className="checkbox">
          <input
            type="checkbox"
            data-testid="field-terms"
            checked={form.acceptTerms}
            onChange={(e) => update('acceptTerms', e.target.checked)}
          />
          Acepto los términos y condiciones
        </label>
        {errors.acceptTerms && <span className="error" data-testid="error-acceptTerms">{errors.acceptTerms}</span>}
      </div>

      <button type="submit" data-testid="button-submit" disabled={submitting}>
        {submitting ? 'Registrando…' : 'Registrarse'}
      </button>
    </form>
  );
}
