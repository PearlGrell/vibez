import { Controller, Get, Query } from '@nestjs/common';
import { SearchService } from './search.service';
import { Filter } from './search.interface';

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  async search(
    @Query('q') query: string,
    @Query('filter') filter?: string,
    @Query('limit') limit?: string,
  ) {
    let filterEnum = Filter.ALL;
    if (filter) {
      const upper = filter.toUpperCase();
      if (upper === 'SONG') {
        filterEnum = Filter.SONG;
      } else if (upper === 'ARTIST') {
        filterEnum = Filter.ARTIST;
      } else if (upper === 'ALBUM') {
        filterEnum = Filter.ALBUM;
      }
    }
    const parsedLimit = limit ? parseInt(limit, 10) : 20;
    return this.searchService.search(query, filterEnum, parsedLimit);
  }
}
