import { Controller, Get, Body, Patch, Param, Delete, Query, UsePipes, Post, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { updateUserSchema, type UpdateUserDto } from './dto/update-user.dto';
import { checkUsernameSchema, type CheckUsernameDto } from './dto/check-username.dto';
import { ZodPipe } from 'src/common/pipes/zod/zod.pipe';
import { CurrentUser, type UserPayload } from 'src/common/decorators/current-user.decorator';
import { AuthGuard } from '../auth/guards/auth.guard';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @UseGuards(AuthGuard)
  findMe(@CurrentUser() user: UserPayload) {
    return this.usersService.me(user);
  }

  @Get('check-username')
  @UsePipes(new ZodPipe(checkUsernameSchema))
  async checkUsername(@Query() query: CheckUsernameDto) {
    const available = await this.usersService.isUsernameAvailable(query.username);
    return { available };
  }

  @Get()
  findAll(@Query('username') username?: string, @Query('page') page?: string, @Query('limit') limit?: string) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 10;
    return this.usersService.findAll(username, pageNum, limitNum);
  }

  @Post(':id/follow')
  @UseGuards(AuthGuard)
  follow(@CurrentUser() user: UserPayload, @Param('id') id: string) {
    return this.usersService.follow(user.sub, id);
  }

  @Post(':id/unfollow')
  @UseGuards(AuthGuard)
  unfollow(@CurrentUser() user: UserPayload, @Param('id') id: string) {
    return this.usersService.unfollow(user.sub, id);
  }

  @Get(':id/followers')
  getFollowers(@Param('id') id: string, @Query('page') page?: string, @Query('limit') limit?: string) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 10;
    return this.usersService.getFollowers(id, pageNum, limitNum);
  }

  @Get(':id/following')
  getFollowing(@Param('id') id: string, @Query('page') page?: string, @Query('limit') limit?: string) {
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 10;
    return this.usersService.getFollowing(id, pageNum, limitNum);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Patch(':id')
  @UsePipes(new ZodPipe(updateUserSchema))
  update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }

  @Post('liked-songs/:songId')
  @UseGuards(AuthGuard)
  likeSong(@CurrentUser() user: UserPayload, @Param('songId') songId: string) {
    return this.usersService.likeSong(user.sub, songId);
  }

  @Delete('liked-songs/:songId')
  @UseGuards(AuthGuard)
  unlikeSong(@CurrentUser() user: UserPayload, @Param('songId') songId: string) {
    return this.usersService.unlikeSong(user.sub, songId);
  }

  @Post('liked-albums/:albumId')
  @UseGuards(AuthGuard)
  likeAlbum(@CurrentUser() user: UserPayload, @Param('albumId') albumId: string) {
    return this.usersService.likeAlbum(user.sub, albumId);
  }

  @Delete('liked-albums/:albumId')
  @UseGuards(AuthGuard)
  unlikeAlbum(@CurrentUser() user: UserPayload, @Param('albumId') albumId: string) {
    return this.usersService.unlikeAlbum(user.sub, albumId);
  }

  @Post('rooms/:roomId/join')
  @UseGuards(AuthGuard)
  joinRoom(@CurrentUser() user: UserPayload, @Param('roomId') roomId: string) {
    return this.usersService.joinRoom(user.sub, roomId);
  }

  @Delete('rooms/:roomId/leave')
  @UseGuards(AuthGuard)
  leaveRoom(@CurrentUser() user: UserPayload, @Param('roomId') roomId: string) {
    return this.usersService.leaveRoom(user.sub, roomId);
  }

  @Post('followed-artists/:artistId')
  @UseGuards(AuthGuard)
  followArtist(@CurrentUser() user: UserPayload, @Param('artistId') artistId: string) {
    return this.usersService.followArtist(user.sub, artistId);
  }

  @Delete('followed-artists/:artistId')
  @UseGuards(AuthGuard)
  unfollowArtist(@CurrentUser() user: UserPayload, @Param('artistId') artistId: string) {
    return this.usersService.unfollowArtist(user.sub, artistId);
  }

  @Post('liked-playlists/:playlistId')
  @UseGuards(AuthGuard)
  likePlaylist(@CurrentUser() user: UserPayload, @Param('playlistId') playlistId: string) {
    return this.usersService.likePlaylist(user.sub, playlistId);
  }

  @Delete('liked-playlists/:playlistId')
  @UseGuards(AuthGuard)
  unlikePlaylist(@CurrentUser() user: UserPayload, @Param('playlistId') playlistId: string) {
    return this.usersService.unlikePlaylist(user.sub, playlistId);
  }
}
