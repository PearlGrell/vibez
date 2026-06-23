import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { SearchService } from './search.service';
import { SearchType } from './search.interface';
import { AuthGuard } from '../auth/guards/auth.guard';
import { CurrentUser, type UserPayload } from 'src/common/decorators/current-user.decorator';

@Controller('search')
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  @UseGuards(AuthGuard)
  async search(
    @CurrentUser() user: UserPayload,
    @Query('q') query: string,
    @Query('filter') filter?: string,
    @Query('limit') limit?: string,
  ) {
    const type = this.parseSearchType(filter);
    const parsedLimit = limit ? parseInt(limit, 10) : 20;
    return this.searchService.search(query, type, parsedLimit, user.sub);
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
