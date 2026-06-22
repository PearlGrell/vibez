import { Module } from '@nestjs/common';
import { SearchService } from './search.service';
import { SearchController } from './search.controller';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { TypeOrmModule } from '@nestjs/typeorm';
import path from 'path';
import { Room } from '../rooms/entities/room.entity';
import { Playlist } from '../users/entities/playlist.entity';
import { User } from '../users/entities/user.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([Room, Playlist, User]),
    ClientsModule.register([
      {
        name: 'SEARCH_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'search',
          protoPath: path.join('/', 'protos', 'search.proto'),
          url: 'grpc:50051',
        },
      },
    ]),
  ],
  controllers: [SearchController],
  providers: [SearchService],
})
export class SearchModule {}
