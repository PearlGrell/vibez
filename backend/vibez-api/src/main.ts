import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ConsoleLogger } from '@nestjs/common';
import cookieParser from 'cookie-parser';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import path from 'path';
import { cwd } from 'process';
import express from 'express';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: new ConsoleLogger({
      colors: true,
      prefix: 'Vibez API',
    }),
  });
  app.use('/', express.static(path.join(process.cwd(), 'public')));
  app.enableCors();
  app.setGlobalPrefix('/api');
  app.use(cookieParser());
  await app.listen(process.env.PORT ?? 3000, () => {
    console.log(`Listening on PORT: ${process.env.PORT}`);
  });
}
bootstrap();
 //dddd