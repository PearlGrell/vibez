import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards, UsePipes } from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { ZodPipe } from 'src/common/pipes/zod/zod.pipe';
import { type CreateRoomDto, createRoomSchema } from './dto/create-room.dto';
import { type UpdateRoomDto, updateRoomSchema } from './dto/update-room.dto';
import { AuthGuard } from '../auth/guards/auth.guard';
import { CurrentUser, type UserPayload } from 'src/common/decorators/current-user.decorator';

@Controller('rooms')
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  @Get()
  async get(
    @Query('limit') limit?: string,
    @Query('page') page?: string,
    @Query('sort') sort?: string,
  ) {
    const parsedLimit = Math.min(Math.max(limit ? parseInt(limit, 10) : 20, 1), 100);
    const parsedPage = Math.max(page ? parseInt(page, 10) : 1, 1);

    const allRooms = await this.roomsService.get();

    let rooms = [...allRooms];
    if (sort === 'newest') {
      rooms.sort((a, b) => {
        const aTime = a.startedAt ? new Date(a.startedAt).getTime() : 0;
        const bTime = b.startedAt ? new Date(b.startedAt).getTime() : 0;
        return bTime - aTime;
      });
    }

    const total = rooms.length;
    const totalPages = Math.ceil(total / parsedLimit);
    const offset = (parsedPage - 1) * parsedLimit;

    return {
      rooms: rooms.slice(offset, offset + parsedLimit),
      total,
      limit: parsedLimit,
      page: parsedPage,
      totalPages,
    };
  }

  @Get('me')
  @UseGuards(AuthGuard)
  async getMyRooms(@CurrentUser() user: UserPayload) {
    return await this.roomsService.getByCreator(user.sub);
  }

  @Get('user/:id')
  async getUserRooms(@Param('id') id: string) {
    return await this.roomsService.getByCreator(id);
  }

  @Get('/:id')
  @UseGuards(AuthGuard)
  async getById(@Param('id') id: string) {
    return await this.roomsService.getById(id);
  }

  @Post()
  @UseGuards(AuthGuard)
  @UsePipes(new ZodPipe(createRoomSchema))
  async create(@Body() body: CreateRoomDto, @CurrentUser() user: UserPayload) {
    return await this.roomsService.create(body.name, body.description, body.tags, body.private, user.sub);
  }


  @Patch('/:id')
  @UseGuards(AuthGuard)
  @UsePipes(new ZodPipe(updateRoomSchema))
  async update(@Param('id') id: string, @Body() body: UpdateRoomDto, @CurrentUser() user: UserPayload) {
    return await this.roomsService.update(id, body, user.sub);
  }

  @Delete('/:id')
  @UseGuards(AuthGuard)
  async delete(@Param('id') id: string, @CurrentUser() user: UserPayload) {
    return await this.roomsService.delete(id, user.sub);
  }
}
