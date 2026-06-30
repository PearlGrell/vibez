import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SongsService } from './songs.service';
import { SongsController } from './songs.controller';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { Song } from './entities/song.entity';
import path from 'path';
import { cwd } from 'process';
import { AuthModule } from '../auth/auth.module';
import { JwtModule } from '@nestjs/jwt';
import { jwtConfig } from 'src/config/jwt.config';

import { Artist } from '../artists/entities/artist.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Song, Artist]),
    ClientsModule.register([
      {
        name: 'SONG_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'song',
          protoPath: path.join('/', 'protos', 'song.proto'),
          url: process.env.GRPC_URL ?? 'grpc:50051',
        },
      },
    ]),
    AuthModule,
    JwtModule.registerAsync(jwtConfig),
  ],
  controllers: [SongsController],
  providers: [SongsService],
  exports: [SongsService],
})
export class SongsModule {}
