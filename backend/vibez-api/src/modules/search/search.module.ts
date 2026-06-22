import { Module } from '@nestjs/common';
import { SearchService } from './search.service';
import { SearchController } from './search.controller';
import { ClientsModule, Transport } from '@nestjs/microservices';
import path from 'path';
import { cwd } from 'process';

@Module({
  imports: [
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
