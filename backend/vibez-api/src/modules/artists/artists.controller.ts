import { Controller, Get, Param, Query, NotFoundException } from '@nestjs/common';
import { ArtistsService } from './artists.service';

@Controller('artists')
export class ArtistsController {
  constructor(private readonly artistsService: ArtistsService) {}

  @Get(':id')
  async getById(@Param('id') id: string) {
    const artist = await this.artistsService.findById(id);
    if (!artist) {
      throw new NotFoundException('Artist not found');
    }
    return artist;
  }

  @Get(':id/songs')
  async getSongs(@Param('id') id: string, @Query('browseId') browseId: string) {
    if (!browseId) {
      throw new NotFoundException('browseId is required');
    }
    const result = await this.artistsService.getArtistSongs(browseId);
    return {
      songs: (result.songs || []).map((s) => ({
        id: s.id,
        title: s.title,
        album: s.albumId ? { id: s.albumId, title: s.album } : null,
        albumId: s.albumId,
        thumbnail: s.thumbnail,
        duration: s.duration || 0,
        artists: s.artists || [],
      })),
    };
  }

  @Get(':id/albums')
  async getAlbums(
    @Param('id') id: string,
    @Query('browseId') browseId?: string,
    @Query('params') params?: string,
  ) {
    const result = await this.artistsService.getArtistAlbums(
      id,
      browseId || '',
      params || '',
    );
    return {
      albums: (result.albums || []).map((a) => ({
        id: a.id,
        title: a.title,
        thumbnail: a.thumbnail,
        type: a.type,
        year: a.year,
      })),
    };
  }
}
