import { randomUUID } from 'node:crypto';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import express from 'express';
import cors from 'cors';

export const COUNTRIES = [
  'España',
  'México',
  'Argentina',
  'Colombia',
  'Chile',
  'Perú',
  'Estados Unidos',
];

// Los mensajes de validación son idénticos a los del frontend (src/lib/validation.ts):
// la suite BDD los usa como contrato entre capas.
const MESSAGES = {
  fullName: 'El nombre debe tener al menos 2 caracteres',
  email: 'Introduce un correo electrónico válido',
  password: 'La contraseña debe tener al menos 8 caracteres e incluir letras y números',
  country: 'Selecciona un país',
  acceptTerms: 'Debes aceptar los términos y condiciones',
};

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const PASSWORD_RE = /^(?=.*[A-Za-z])(?=.*\d).{8,}$/;

export function validateUser(payload = {}) {
  const errors = {};
  const normalized = {
    fullName: String(payload.fullName ?? '').trim(),
    email: String(payload.email ?? '').trim().toLowerCase(),
    password: String(payload.password ?? ''),
    country: String(payload.country ?? '').trim(),
    birthdate: payload.birthdate ? String(payload.birthdate) : null,
  };

  if (normalized.fullName.length < 2) errors.fullName = MESSAGES.fullName;
  if (!EMAIL_RE.test(normalized.email)) errors.email = MESSAGES.email;
  if (!PASSWORD_RE.test(normalized.password)) errors.password = MESSAGES.password;
  if (!COUNTRIES.includes(normalized.country)) errors.country = MESSAGES.country;
  if (payload.acceptTerms !== true) errors.acceptTerms = MESSAGES.acceptTerms;

  return { errors, valid: Object.keys(errors).length === 0, normalized };
}

export function createApp({ logger = console } = {}) {
  const app = express();
  const usersByEmail = new Map(); // demo: almacén en memoria; en producción sería una BD gestionada

  app.use(cors());
  app.use(express.json());

  // Observabilidad ligera: correlaciona las peticiones con las ejecuciones de pruebas
  app.use((req, _res, next) => {
    logger.info(`${new Date().toISOString()} ${req.method} ${req.originalUrl}`);
    next();
  });

  app.get('/api/health', (_req, res) => {
    res.json({
      status: 'ok',
      env: process.env.APP_ENV ?? 'local',
      version: '1.0.0',
      uptimeSeconds: Math.round(process.uptime()),
      totalUsers: usersByEmail.size,
    });
  });

  app.get('/api/countries', (_req, res) => res.json({ countries: COUNTRIES }));

  app.get('/api/users', (_req, res) => {
    const users = [...usersByEmail.values()].map(({ password, ...safe }) => safe);
    res.json({ total: users.length, users });
  });

  app.get('/api/users/:id', (req, res) => {
    const user = [...usersByEmail.values()].find((u) => u.id === req.params.id);
    if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
    const { password, ...safe } = user;
    return res.json(safe);
  });

  app.post('/api/users', (req, res) => {
    const { errors, valid, normalized } = validateUser(req.body);
    if (!valid) return res.status(400).json({ message: 'Datos de registro inválidos', errors });

    if (usersByEmail.has(normalized.email)) {
      return res.status(409).json({
        message: 'El correo electrónico ya está registrado',
        errors: { email: 'El correo electrónico ya está registrado' },
      });
    }

    const user = { id: randomUUID(), createdAt: new Date().toISOString(), ...normalized };
    usersByEmail.set(user.email, user);
    const { password: _pwd, ...safeUser } = user;
    return res.status(201).json(safeUser); // la API nunca devuelve la contraseña
  });

  // Utilidad de aislamiento para las pruebas: resetea el estado entre ejecuciones
  app.post('/api/__test__/reset', (_req, res) => {
    usersByEmail.clear();
    res.status(204).end();
  });

  // Frontend compilado (build de React). En local sin build, el frontend usa Vite en el puerto 5173.
  const staticCandidates = [
    process.env.STATIC_DIR,
    fileURLToPath(new URL('../public', import.meta.url)), // paquete desplegado en Azure
    fileURLToPath(new URL('../../frontend/dist', import.meta.url)), // ejecución local
  ].filter(Boolean);
  const staticDir = staticCandidates.find((dir) => existsSync(resolve(dir, 'index.html')))
    ?? staticCandidates[staticCandidates.length - 1];
  const indexPath = resolve(staticDir, 'index.html');

  app.use(express.static(staticDir));
  app.get(/^\/(?!api\/).*/, (_req, res) => res.sendFile(indexPath));

  return app;
}
