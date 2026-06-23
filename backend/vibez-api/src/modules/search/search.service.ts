import { Injectable, Inject, OnModuleInit } from '@nestjs/common';
import { type ClientGrpc } from '@nestjs/microservices';
import { InjectRepository } from '@nestjs/typeorm';
import { ILike, Repository } from 'typeorm';
import { firstValueFrom } from 'rxjs';
import { SearchGrpcService, Filter, SearchType } from './search.interface';
import { Room } from '../rooms/entities/room.entity';
import { Playlist } from '../users/entities/playlist.entity';
import { User } from '../users/entities/user.entity';

interface CacheEntry {
  data: any;
  timestamp: number;
}

@Injectable()
export class SearchService implements OnModuleInit {
  private grpcService: SearchGrpcService;
  private dbCache = new Map<string, CacheEntry>();
  private readonly CACHE_TTL = 60_000;
  private readonly MAX_CACHE_SIZE = 200;

  constructor(
    @Inject('SEARCH_PACKAGE')
    private readonly client: ClientGrpc,
    @InjectRepository(Room)
    private readonly roomRepo: Repository<Room>,
    @InjectRepository(Playlist)
    private readonly playlistRepo: Repository<Playlist>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  onModuleInit() {
    this.grpcService = this.client.getService<SearchGrpcService>('Search');
  }

  private static readonly GRPC_TYPES = new Set([
    SearchType.ALL,
    SearchType.SONG,
    SearchType.ARTIST,
    SearchType.ALBUM,
  ]);

  private static readonly GRPC_FILTER_MAP: Record<string, Filter> = {
    [SearchType.SONG]: Filter.SONG,
    [SearchType.ARTIST]: Filter.ARTIST,
    [SearchType.ALBUM]: Filter.ALBUM,
  };

  async search(query: string, type: SearchType = SearchType.ALL, limit = 20, userId?: string) {
    const wantsGrpc = SearchService.GRPC_TYPES.has(type);
    const wantsRooms = type === SearchType.ALL || type === SearchType.ROOM;
    const wantsPlaylists = type === SearchType.ALL || type === SearchType.PLAYLIST;
    const wantsUsers = type === SearchType.ALL || type === SearchType.USER;

    const grpcFilter = SearchService.GRPC_FILTER_MAP[type] ?? Filter.ALL;

    const [grpcResult, rooms, playlists, users] = await Promise.all([
      wantsGrpc
        ? firstValueFrom(
            this.grpcService.Search({ query, filter: grpcFilter, limit }),
          )
        : { songs: [], artists: [], albums: [] },
      wantsRooms ? this.getCachedRooms(query, limit) : [],
      wantsPlaylists ? this.getCachedPlaylists(query, limit) : [],
      wantsUsers ? this.getCachedUsers(query, limit, userId) : [],
    ]);

    return {
      songs: grpcResult.songs ?? [],
      artists: grpcResult.artists ?? [],
      albums: grpcResult.albums ?? [],
      playlists,
      rooms,
      users,
    };
  }

  private async getCachedRooms(query: string, limit: number) {
    const key = `rooms:${query.toLowerCase().trim()}:${limit}`;
    const cached = this.dbCache.get(key);
    if (cached && Date.now() - cached.timestamp < this.CACHE_TTL) {
      return cached.data;
    }
    const data = await this.searchRooms(query, limit);
    this.setCacheEntry(key, data);
    return data;
  }

  private async getCachedPlaylists(query: string, limit: number) {
    const key = `playlists:${query.toLowerCase().trim()}:${limit}`;
    const cached = this.dbCache.get(key);
    if (cached && Date.now() - cached.timestamp < this.CACHE_TTL) {
      return cached.data;
    }
    const data = await this.searchPlaylists(query, limit);
    this.setCacheEntry(key, data);
    return data;
  }

  private async getCachedUsers(query: string, limit: number, userId?: string) {
    const key = `users:${query.toLowerCase().trim()}:${limit}:${userId ?? ''}`;
    const cached = this.dbCache.get(key);
    if (cached && Date.now() - cached.timestamp < this.CACHE_TTL) {
      return cached.data;
    }
    const data = await this.searchUsers(query, limit, userId);
    this.setCacheEntry(key, data);
    return data;
  }

  private setCacheEntry(key: string, data: any) {
    this.dbCache.set(key, { data, timestamp: Date.now() });
    if (this.dbCache.size > this.MAX_CACHE_SIZE) {
      const now = Date.now();
      for (const [k, entry] of this.dbCache.entries()) {
        if (now - entry.timestamp > this.CACHE_TTL) {
          this.dbCache.delete(k);
        }
      }
    }
  }

  private async searchRooms(query: string, limit: number) {
    return this.roomRepo.find({
      where: [
        { private: false, name: ILike(`%${query}%`) },
        { private: false, description: ILike(`%${query}%`) },
      ],
      take: limit,
    });
  }

  private async searchPlaylists(query: string, limit: number) {
    return this.playlistRepo.find({
      where: [
        { private: false, name: ILike(`%${query}%`) },
        { private: false, description: ILike(`%${query}%`) },
      ],
      take: limit,
    });
  }

  private async searchUsers(query: string, limit: number, userId?: string) {
    const qb = this.userRepo
      .createQueryBuilder('user')
      .where('(user.username ILIKE :q OR user.name ILIKE :q)', {
        q: `%${query}%`,
      });

    if (userId) {
      qb.andWhere('user.id != :userId', { userId });
    }

    return qb.take(limit).getMany();
  }
}
