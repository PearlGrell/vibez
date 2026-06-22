import { Controller, Get, Param, NotFoundException, UseGuards } from '@nestjs/common';
import { SongsService } from './songs.service';
import { AuthGuard } from '../auth/guards/auth.guard';

@Controller('songs')
export class SongsController {
  constructor(private readonly songsService: SongsService) {}

  @Get(':id')
  async getById(@Param('id') id: string) {
    const song = await this.songsService.findById(id);
    if (!song) {
      throw new NotFoundException('Song not found');
    }
    return song;
  }

  @Get(':id/play')
  @UseGuards(AuthGuard)
  async play(@Param('id') id: string) {
    const [song, audio] = await Promise.all([
      this.songsService.findById(id),
      this.songsService.getAudio(id),
    ]);
    if (!song) {
      throw new NotFoundException('Song not found');
    }
    return audio;
  }

  @Get(':id/lyrics')
  @UseGuards(AuthGuard)
  async getLyrics(@Param('id') id: string) {
    const [song, lyrics] = await Promise.all([
      this.songsService.findById(id),
      this.songsService.getLyrics(id),
    ]);
    if (!song) {
      throw new NotFoundException('Song not found');
    }
    return lyrics;
  }

  @Get(':id/related')
  @UseGuards(AuthGuard)
  async getRelated(@Param('id') id: string) {
    const [song, related] = await Promise.all([
      this.songsService.findById(id),
      this.songsService.getRelated(id),
    ]);
    if (!song) {
      throw new NotFoundException('Song not found');
    }
    return related;
  }

  @Get(':id/credits')
  @UseGuards(AuthGuard)
  async getCredits(@Param('id') id: string) {
    const [song, credits] = await Promise.all([
      this.songsService.findById(id),
      this.songsService.getCredits(id),
    ]);
    if (!song) {
      throw new NotFoundException('Song not found');
    }
    return credits;
  }
}
