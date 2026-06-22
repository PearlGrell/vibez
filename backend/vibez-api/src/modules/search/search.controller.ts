import { Controller, Get, Query } from '@nestjs/common';
import { SearchService } from './search.service';
import { SearchType } from './search.interface';

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  async search(
    @Query('q') query: string,
    @Query('filter') filter?: string,
    @Query('limit') limit?: string,
  ) {
    const type = this.parseSearchType(filter);
    const parsedLimit = limit ? parseInt(limit, 10) : 20;
    return this.searchService.search(query, type, parsedLimit);
  }

  private parseSearchType(filter?: string): SearchType {
    if (!filter) return SearchType.ALL;
    const value = filter.toLowerCase();
    if (Object.values(SearchType).includes(value as SearchType)) {
      return value as SearchType;
    }
    return SearchType.ALL;
  }
}
