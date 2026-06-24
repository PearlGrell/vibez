import { Injectable, Inject, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Song } from './entities/song.entity';
import { Artist } from '../artists/entities/artist.entity';
import { type ClientGrpc } from '@nestjs/microservices';
import { firstValueFrom } from 'rxjs';
import { SongGrpcService, AudioResponse, LyricsResponse, RelatedResponse, CreditsResponse } from './songs.interface';

@Injectable()
export class SongsService implements OnModuleInit {
  private grpcService: SongGrpcService;

  private readonly songCache = new Map<string, { data: any; fetchedAt: number }>();
  private readonly SONG_CACHE_TTL = 1800_000;
  private readonly audioCache = new Map<string, { audio: AudioResponse; fetchedAt: number }>();
  private readonly lyricsCache = new Map<string, LyricsResponse>();
  private readonly relatedCache = new Map<string, RelatedResponse>();
  private readonly creditsCache = new Map<string, CreditsResponse>();

  constructor(
    @InjectRepository(Song)
    private readonly songRepository: Repository<Song>,
    @InjectRepository(Artist)
    private readonly artistRepository: Repository<Artist>,
    @Inject('SONG_PACKAGE')
    private readonly client: ClientGrpc,
  ) {}

  onModuleInit() {
    this.grpcService = this.client.getService<SongGrpcService>('Song');
  }

  async findById(id: string): Promise<any | null> {
    const cached = this.songCache.get(id);
    if (cached && Date.now() - cached.fetchedAt < this.SONG_CACHE_TTL) {
      return cached.data;
    }

    const song = await this.songRepository.findOne({
      where: { id },
      relations: { album: { artists: true }, artists: true },
    });

    if (!song) {
      try {
        const response = await firstValueFrom(this.grpcService.Song({ id }));
        if (response && response.id) {
          const formatted = {
            id: response.id,
            title: response.title,
            duration: response.duration,
            thumbnail: response.thumbnail,
            year: response.year,
            album: response.albumId ? { id: response.albumId, title: response.album } : null,
            artists: response.artists || [],
          };
          this.songCache.set(id, { data: formatted, fetchedAt: Date.now() });
          return formatted;
        }
      } catch (err) {
        console.error(`Failed to fetch song ${id} from gRPC:`, err);
        return null;
      }
      return null;
    }

    this.songCache.set(id, { data: song, fetchedAt: Date.now() });
    return song;
  }

  async save(song: Partial<Song>): Promise<Song> {
    if (song.id) this.songCache.delete(song.id);
    return this.songRepository.save(song);
  }

  async findOrCreate(id: string, title: string, extraData?: Partial<Song>): Promise<Song> {
    this.songCache.delete(id);

    const existing = await this.songRepository.findOne({
      where: { id },
      relations: { album: { artists: true }, artists: true },
    });
    if (existing) {
      return existing;
    }
    const { artistIds, artists: artistData, ...rest } = (extraData as any) || {};
    const song = this.songRepository.create({ id, title, ...rest } as any) as unknown as Song;
    const ids: string[] = artistIds || (artistData ? artistData.map((a: any) => a.id) : []);
    const nameMap = new Map<string, string>();
    if (artistData) {
      for (const a of artistData) {
        if (a.id && a.name) nameMap.set(a.id, a.name);
      }
    }
    if (ids.length > 0) {
      const existingArtists = await this.artistRepository.find({
        where: { id: In(ids) },
      });
      const existingArtistsMap = new Map(existingArtists.map((a) => [a.id, a]));

      const missingArtistIds = ids.filter((id: string) => !existingArtistsMap.has(id));
      if (missingArtistIds.length > 0) {
        const newArtists = missingArtistIds.map((id: string) =>
          this.artistRepository.create({ id, name: nameMap.get(id) || 'Unknown Artist' }),
        );
        await this.artistRepository.save(newArtists);
        newArtists.forEach((artist: Artist) => existingArtistsMap.set(artist.id, artist));
      }

      for (const [artistId, artist] of existingArtistsMap) {
        if (artist.name === 'Unknown Artist' && nameMap.has(artistId)) {
          artist.name = nameMap.get(artistId)!;
          await this.artistRepository.save(artist);
        }
      }

      song.artists = ids.map((id: string) => existingArtistsMap.get(id)!);
    }
    await this.songRepository.save(song);

    const reloaded = await this.songRepository.findOne({
      where: { id },
      relations: { album: { artists: true }, artists: true },
    });
    if (!reloaded) {
      throw new Error('Failed to reload song');
    }
    return reloaded;
  }

  async getAudio(id: string): Promise<AudioResponse> {
    const cached = this.audioCache.get(id);
    const now = Date.now();
    if (cached && (now - cached.fetchedAt < 1800000)) {
      return cached.audio;
    }
    const audio = await firstValueFrom(this.grpcService.Audio({ id }));
    this.audioCache.set(id, { audio, fetchedAt: now });
    return audio;
  }

  async getLyrics(id: string): Promise<LyricsResponse> {
    if (this.lyricsCache.has(id)) {
      return this.lyricsCache.get(id)!;
    }
    const lyrics = await firstValueFrom(this.grpcService.Lyrics({ id }));
    this.lyricsCache.set(id, lyrics);
    return lyrics;
  }

  async getRelated(id: string, limit = 5): Promise<RelatedResponse> {
    const cacheKey = `${id}_${limit}`;
    if (this.relatedCache.has(cacheKey)) {
      return this.relatedCache.get(cacheKey)!;
    }
    const related = await firstValueFrom(this.grpcService.Related({ id, limit }));
    this.relatedCache.set(cacheKey, related);
    return related;
  }

  async getCredits(id: string): Promise<CreditsResponse> {
    if (this.creditsCache.has(id)) {
      return this.creditsCache.get(id)!;
    }
    const credits = await firstValueFrom(this.grpcService.Credits({ id }));
    this.creditsCache.set(id, credits);
    return credits;
  }
}
