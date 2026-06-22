import { Controller, Get, Param, NotFoundException } from '@nestjs/common';
import { AlbumsService } from './albums.service';

@Controller('albums')
export class AlbumsController {
  constructor(private readonly albumsService: AlbumsService) {}

  @Get(':id')
  async getById(@Param('id') id: string) {
    const album = await this.albumsService.findById(id);
    if (!album) {
      throw new NotFoundException('Album not found');
    }
    return album;
  }
}
