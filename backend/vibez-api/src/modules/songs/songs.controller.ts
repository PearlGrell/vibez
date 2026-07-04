import { Controller, Get, Param, NotFoundException, Req, Res, UseGuards } from '@nestjs/common';
import { type Request, type Response } from 'express';
import http from 'http';
import { SongsService } from './songs.service';
import { AuthGuard } from '../auth/guards/auth.guard';

@Controller('songs')
export class SongsController {
  constructor(private readonly songsService: SongsService) {}

  /**
   * Relays audio bytes from the gRPC service's stream relay. The relay
   * extracts and fetches from the same IP, which is the only way a
   * server-resolved stream URL is playable (they are IP-bound).
   * No auth guard: players issue plain ranged GETs without headers.
   */
  @Get(':id/stream')
  stream(@Param('id') id: string, @Req() req: Request, @Res() res: Response) {
    const base = process.env.STREAM_RELAY_URL ?? 'http://grpc:8080';
    const headers: Record<string, string> = {};
    if (req.headers.range) {
      headers.range = req.headers.range as string;
    }

    const upstream = http.get(`${base}/stream/${encodeURIComponent(id)}`, { headers }, (up) => {
      res.status(up.statusCode ?? 502);
      for (const header of ['content-type', 'content-length', 'content-range', 'accept-ranges'] as const) {
        const value = up.headers[header];
        if (value) {
          res.setHeader(header, value);
        }
      }
      up.pipe(res);
    });
    upstream.on('error', () => {
      if (!res.headersSent) {
        res.status(502).json({ message: 'Stream relay unavailable' });
      } else {
        res.end();
      }
    });
    req.on('close', () => upstream.destroy());
  }

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
