import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth';
import circleRoutes from './routes/circles';
import journeyRoutes from './routes/journeys';
import notificationRoutes from './routes/notifications';
import workplaceRoutes from './routes/workplaces';
import matchRoutes from './routes/matches';
import reliabilityRoutes from './routes/reliability';
import metricsRoutes from './routes/metrics';
import jobRoutes from './routes/jobs';
import messageRoutes from './routes/messages';
import { getRuntimeConfig } from './lib/runtimeConfig';

export function createApp() {
  const { corsOrigin } = getRuntimeConfig();
  const app = express();
  app.use(cors({ origin: corsOrigin }));
  app.use(express.json());

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.use('/auth', authRoutes);
  app.use('/workplaces', workplaceRoutes);
  app.use('/matches', matchRoutes);
  app.use('/reliability', reliabilityRoutes);
  app.use('/metrics', metricsRoutes);
  app.use('/jobs', jobRoutes);
  app.use('/circles', circleRoutes);
  app.use('/journeys', journeyRoutes);
  app.use('/notifications', notificationRoutes);
  app.use(messageRoutes);

  return app;
}
