import { Injectable, Inject, OnModuleInit } from '@nestjs/common';
import { type ClientGrpc } from '@nestjs/microservices';
import { firstValueFrom } from 'rxjs';
import { SearchGrpcService, Filter } from './search.interface';

@Injectable()
export class SearchService implements OnModuleInit {
  private grpcService: SearchGrpcService;

  constructor(
    @Inject('SEARCH_PACKAGE')
    private readonly client: ClientGrpc,
  ) {}

  onModuleInit() {
    this.grpcService = this.client.getService<SearchGrpcService>('Search');
  }

  async search(query: string, filter: Filter = Filter.ALL, limit = 20) {
    return firstValueFrom(
      this.grpcService.Search({
        query,
        filter,
        limit,
      }),
    );
  }
}
