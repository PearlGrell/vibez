import { Body, Controller, Get, Param, Post, Query, UseGuards, UsePipes } from '@nestjs/common';
import { PlaylistsService } from './playlists.service';
import { AuthGuard } from '../../auth/guards/auth.guard';
import { ZodPipe } from 'src/common/pipes/zod/zod.pipe';
import { CurrentUser, type UserPayload } from 'src/common/decorators/current-user.decorator';
import { type CreatePlaylistDto, createPlaylistSchema } from '../dto/create-playlist.dto';
import { type UpdatePlaylistDto, updatePlaylistSchema } from '../dto/update-playlist.dto';
import { type AddSongDto, addSongSchema } from './dto/add-song.dto';

@Controller('users/playlists')
@UseGuards(AuthGuard)
export class PlaylistsController {
  constructor(private readonly playlistsService: PlaylistsService) {}

  @Post()
  @UsePipes(new ZodPipe(createPlaylistSchema))
  create(@CurrentUser() user: UserPayload, @Body() body: CreatePlaylistDto) {
    return this.playlistsService.create(user.sub, body.name, body.private, body.tags, body.thumbnail, body.description);
  }

  @Post(':id')
  @UsePipes(new ZodPipe(updatePlaylistSchema))
  update(@CurrentUser() user: UserPayload, @Body() body: UpdatePlaylistDto, @Param('id') id: string) {
    return this.playlistsService.update(user.sub, id, body.name, body.private, body.tags, body.thumbnail, body.description);
  }

  @Get()
  getPlaylists(@Query('limit') limit?: string) {
    const parsedLimit = limit ? parseInt(limit, 10) : 20;
    return this.playlistsService.getPlaylists(parsedLimit);
  }

  @Get(':id')
  findOne(@CurrentUser() user: UserPayload, @Param('id') id: string) {
    return this.playlistsService.findOne(id, user.sub);
  }

  @Post(':id/songs')
  @UsePipes(new ZodPipe(addSongSchema))
  addSong(@CurrentUser() user: UserPayload, @Param('id') id: string, @Body() body: AddSongDto) {
    return this.playlistsService.addSong(user.sub, id, body.songId);
  }
}
