import { Injectable, Inject, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Album } from './entities/album.entity';
import { Artist } from '../artists/entities/artist.entity';
import { type ClientGrpc } from '@nestjs/microservices';
import { firstValueFrom } from 'rxjs';
import { AlbumGrpcService } from './albums.interface';

@Injectable()
export class AlbumsService implements OnModuleInit {
  private grpcService: AlbumGrpcService;

  constructor(
    @InjectRepository(Album)
    private readonly albumRepository: Repository<Album>,
    @InjectRepository(Artist)
    private readonly artistRepository: Repository<Artist>,
    @Inject('ALBUM_PACKAGE')
    private readonly client: ClientGrpc,
  ) {}

  onModuleInit() {
    this.grpcService = this.client.getService<AlbumGrpcService>('Album');
  }

  async findById(id: string): Promise<any | null> {
    let dbAlbum = await this.albumRepository.findOne({
      where: { id },
    });

    try {
      const response = await firstValueFrom(this.grpcService.Album({ id }));
      if (response && response.id) {
        if (!dbAlbum) {
          dbAlbum = this.albumRepository.create({ id, title: response.title });
        } else {
          dbAlbum.title = response.title;
        }
        dbAlbum.type = response.type;
        dbAlbum.thumbnail = response.thumbnail;
        dbAlbum.isExplicit = response.isExplicit;
        dbAlbum.description = response.description;
        dbAlbum.year = response.year;
        dbAlbum.trackCount = response.trackCount;
        dbAlbum.durationSeconds = response.durationSeconds;

        await this.albumRepository.save(dbAlbum);

        return {
          id: response.id,
          title: response.title,
          type: response.type,
          thumbnail: response.thumbnail,
          isExplicit: response.isExplicit,
          description: response.description,
          year: response.year,
          trackCount: response.trackCount,
          durationSeconds: response.durationSeconds,
          artists: response.artists || [],
          songs: (response.tracks || []).map((t) => ({
            id: t.videoId,
            title: t.title,
            duration: t.durationSeconds,
            thumbnail: t.thumbnail,
            isExplicit: t.isExplicit,
            trackNumber: t.trackNumber,
            artists: t.artists || [],
          })),
        };
      }
    } catch (err) {
      console.error(`Failed to fetch album ${id} from gRPC:`, err);
    }

    if (dbAlbum) {
      const albumWithRelations = await this.albumRepository.findOne({
        where: { id },
        relations: { songs: { artists: true }, artists: true },
      });
      return albumWithRelations;
    }

    return null;
  }

  async save(album: Partial<Album>): Promise<Album> {
    return this.albumRepository.save(album);
  }

  async findOrCreate(id: string, title: string, extraData?: Partial<Album>): Promise<Album> {
    const existing = await this.albumRepository.findOne({
      where: { id },
      relations: { songs: { artists: true }, artists: true },
    });
    if (existing) {
      return existing;
    }
    const { artistIds, ...rest } = (extraData as any) || {};
    const album = this.albumRepository.create({ id, title, ...rest } as any) as unknown as Album;
    if (artistIds && artistIds.length > 0) {
      const artists = await Promise.all(
        artistIds.map(async (artistId: string) => {
          let artist = await this.artistRepository.findOne({ where: { id: artistId } });
          if (!artist) {
            artist = this.artistRepository.create({ id: artistId, name: 'Unknown Artist' });
            await this.artistRepository.save(artist);
          }
          return artist;
        }),
      );
      album.artists = artists;
    }
    await this.albumRepository.save(album);

    const reloaded = await this.albumRepository.findOne({
      where: { id },
      relations: { songs: { artists: true }, artists: true },
    });
    if (!reloaded) {
      throw new Error('Failed to reload album');
    }
    return reloaded;
  }
}
