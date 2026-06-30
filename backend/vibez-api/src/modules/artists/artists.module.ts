import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ArtistsService } from './artists.service';
import { ArtistsController } from './artists.controller';
import { Artist } from './entities/artist.entity';
import { ClientsModule, Transport } from '@nestjs/microservices';
import path from 'path';
import { cwd } from 'process';

import { Song } from '../songs/entities/song.entity';
import { Album } from '../albums/entities/album.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Artist, Song, Album]),
    ClientsModule.register([
      {
        name: 'ARTIST_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'artist',
          protoPath: path.join('/', 'protos', 'artist.proto'),
          url: process.env.GRPC_URL ?? 'grpc:50051',
        },
      },
    ]),
  ],
  controllers: [ArtistsController],
  providers: [ArtistsService],
  exports: [ArtistsService],
})
export class ArtistsModule {}
