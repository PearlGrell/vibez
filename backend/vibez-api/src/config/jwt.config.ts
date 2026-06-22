import { ConfigService } from '@nestjs/config';
import { JwtModuleAsyncOptions } from '@nestjs/jwt';

export const jwtConfig: JwtModuleAsyncOptions = {
  inject: [ConfigService],
  useFactory: (config: ConfigService) => ({
    secret: config.get<string>('jwt.secret'),
    signOptions: {
      expiresIn: config.get('jwt.expiresIn'),
    },
  }),
};
