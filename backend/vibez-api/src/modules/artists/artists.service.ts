import { Injectable, Inject, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ArrayContains, In } from 'typeorm';
import { Artist } from './entities/artist.entity';
import { Song } from '../songs/entities/song.entity';
import { Album } from '../albums/entities/album.entity';
import { type ClientGrpc } from '@nestjs/microservices';
import { firstValueFrom } from 'rxjs';
import { ArtistGrpcService, ArtistSongsResponse, ArtistAlbumsResponse } from './artists.interface';

@Injectable()
export class ArtistsService implements OnModuleInit {
  private grpcService: ArtistGrpcService;

  constructor(
    @InjectRepository(Artist)
    private readonly artistRepository: Repository<Artist>,
    @InjectRepository(Song)
    private readonly songRepository: Repository<Song>,
    @InjectRepository(Album)
    private readonly albumRepository: Repository<Album>,
    @Inject('ARTIST_PACKAGE')
    private readonly client: ClientGrpc,
  ) {}

  onModuleInit() {
    this.grpcService = this.client.getService<ArtistGrpcService>('Artist');
  }

  async findById(id: string): Promise<any | null> {
    let dbArtist = await this.artistRepository.findOne({
      where: { id },
    });

    try {
      const response = await firstValueFrom(this.grpcService.Artist({ id }));
      if (response && response.id) {
        if (!dbArtist) {
          dbArtist = this.artistRepository.create({ id, name: response.name });
        } else {
          dbArtist.name = response.name;
        }
        dbArtist.description = response.description;
        dbArtist.monthlyListeners = response.monthlyListeners;
        dbArtist.subscribers = response.subscribers;
        dbArtist.views = response.views;
        dbArtist.thumbnail = response.thumbnail;
        
        await this.artistRepository.save(dbArtist);

        return {
          id: response.id,
          name: response.name,
          description: response.description,
          views: response.views,
          subscribers: response.subscribers,
          monthlyListeners: response.monthlyListeners,
          thumbnail: response.thumbnail,
          songsBrowseId: response.songsBrowseId || '',
          albumsBrowseId: response.albumsBrowseId || '',
          albumsParams: response.albumsParams || '',
          songs: (response.songs || []).map((s) => ({
            id: s.id,
            title: s.title,
            album: s.albumId ? { id: s.albumId, title: s.album } : null,
            albumId: s.albumId,
            thumbnail: s.thumbnail,
            duration: s.duration || 0,
            artists: s.artists || [],
          })),
          albums: (response.albums || []).concat(response.singles || []).map((a) => ({
            id: a.id,
            title: a.title,
            thumbnail: a.thumbnail,
            type: a.type,
            year: a.year,
          })),
        };
      }
    } catch (err) {
      console.error(`Failed to fetch artist ${id} from gRPC:`, err);
    }

    if (dbArtist) {
      const artistWithRelations = await this.artistRepository.findOne({
        where: { id },
        relations: {
          songs: { artists: true },
          albums: { artists: true, songs: { artists: true } },
        },
      });
      return artistWithRelations;
    }

    return null;
  }

  async save(artist: Partial<Artist>): Promise<Artist> {
    return this.artistRepository.save(artist);
  }

  async getArtistSongs(browseId: string): Promise<ArtistSongsResponse> {
    return firstValueFrom(
      this.grpcService.ArtistSongs({ channelId: '', browseId, params: '' }),
    );
  }

  async getArtistAlbums(channelId: string, browseId: string, params: string): Promise<ArtistAlbumsResponse> {
    return firstValueFrom(
      this.grpcService.ArtistAlbums({ channelId, browseId, params }),
    );
  }

  async findOrCreate(id: string, name: string, extraData?: Partial<Artist>): Promise<Artist> {
    const existing = await this.artistRepository.findOne({
      where: { id },
      relations: {
        songs: { artists: true },
        albums: { artists: true, songs: { artists: true } },
      },
    });
    if (existing) {
      return existing;
    }
    const artist = this.artistRepository.create({ id, name, ...extraData });
    await this.artistRepository.save(artist);

    const reloaded = await this.artistRepository.findOne({
      where: { id },
      relations: {
        songs: { artists: true },
        albums: { artists: true, songs: { artists: true } },
      },
    });
    if (!reloaded) {
      throw new Error('Failed to reload artist');
    }
    return reloaded;
  }
}
