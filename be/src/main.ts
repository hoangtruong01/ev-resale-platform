import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { RequestMethod } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads/',
  });

  // Set global prefix for all routes
  app.setGlobalPrefix('api');

  // Enable CORS for frontend communication
  app.enableCors({
    origin: (origin, callback) => {
      if (!origin) {
        callback(null, true);
        return;
      }

      const allowed = [
        'http://localhost:3000',
        'http://localhost:3001',
        process.env.FRONTEND_URL ?? '',
      ].filter(Boolean);

      const isLocalhost = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(
        origin,
      );

      if (allowed.includes(origin) || isLocalhost) {
        callback(null, true);
        return;
      }

      callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });

  // Swagger Configuration (setup before global prefix)
  const config = new DocumentBuilder()
    .setTitle('Second-hand EVN Battery Trading Platform API')
    .setDescription('API documentation for the EV Battery Trading Platform')
    .setVersion('1.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'JWT',
        description: 'Enter JWT token',
        in: 'header',
      },
      'JWT-auth', // This name here is important for matching up with @ApiBearerAuth() in your controller!
    )
    .addTag('Health', 'Health check endpoints')
    .addTag('Auth', 'Authentication endpoints')
    .addTag('Batteries', 'Battery management endpoints')
    .addTag('Vehicles', 'Vehicle management endpoints')
    .addTag('Auctions', 'Auction management endpoints')
    .addTag('Files', 'File upload endpoints')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
    },
    customSiteTitle: 'EVN Battery Trading API Docs',
  });

  // Set global prefix for all routes, but allow OAuth callbacks without prefix
  app.setGlobalPrefix('api', {
    exclude: [
      { path: 'auth/google', method: RequestMethod.GET },
      { path: 'auth/google/callback', method: RequestMethod.GET },
      { path: 'auth/facebook', method: RequestMethod.GET },
      { path: 'auth/facebook/callback', method: RequestMethod.GET },
    ],
  });

  await app.listen(process.env.PORT ?? 3000);

  console.log(
    `🚀 Application is running on: http://localhost:${process.env.PORT ?? 3000}`,
  );
  console.log(
    `📚 Swagger documentation: http://localhost:${process.env.PORT ?? 3000}/api`,
  );
}
bootstrap();
