import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth';
import circleRoutes from './routes/circles';
import journeyRoutes from './routes/journeys';
import notificationRoutes from './routes/notifications';
import { getRuntimeConfig } from './lib/runtimeConfig';

const { corsOrigin } = getRuntimeConfig();
const app = express();
app.use(cors({ origin: corsOrigin }));
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/auth', authRoutes);
app.use('/circles', circleRoutes);
app.use('/journeys', journeyRoutes);
app.use('/notifications', notificationRoutes);

const PORT = process.env.PORT ?? 3000;
app.listen(PORT, () => {
  console.log(`Coleggo backend listening on port ${PORT}`);
});
