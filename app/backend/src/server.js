import { createApp } from './app.js';

const port = Number(process.env.PORT ?? 3000);
const app = createApp();

app.listen(port, () => {
  console.log(`API y frontend disponibles en http://localhost:${port} (env: ${process.env.APP_ENV ?? 'local'})`);
});
