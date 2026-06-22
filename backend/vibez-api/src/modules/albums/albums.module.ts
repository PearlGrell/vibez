import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AlbumsService } from './albums.service';
import { AlbumsController } from './albums.controller';
import { Album } from './entities/album.entity';
import { ClientsModule, Transport } from '@nestjs/microservices';
import path from 'path';
import { cwd } from 'process';

import { Artist } from '../artists/entities/artist.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Album, Artist]),
    ClientsModule.register([
      {
        name: 'ALBUM_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'album',
          protoPath: path.join('/', 'protos', 'album.proto'),
          url: 'grpc:50051',
        },
      },
    ]),
  ],
  controllers: [AlbumsController],
  providers: [AlbumsService],
  exports: [AlbumsService],
})
export class AlbumsModule {}
