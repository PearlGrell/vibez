import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { SongsService } from '../songs/songs.service';
import { AlbumsService } from '../albums/albums.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { Session } from '../auth/entities/session.entity';
import { Song } from '../songs/entities/song.entity';
import { Album } from '../albums/entities/album.entity';
import { Room } from '../rooms/entities/room.entity';
import { Playlist } from './entities/playlist.entity';
import { Artist } from '../artists/entities/artist.entity';
import { ArtistsService } from '../artists/artists.service';
import { Repository } from 'typeorm';
import { UserPayload } from 'src/common/decorators/current-user.decorator';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Session)
    private readonly sessionRepository: Repository<Session>,
    @InjectRepository(Song)
    private readonly songRepository: Repository<Song>,
    @InjectRepository(Album)
    private readonly albumRepository: Repository<Album>,
    @InjectRepository(Room)
    private readonly roomRepository: Repository<Room>,
    @InjectRepository(Playlist)
    private readonly playlistRepository: Repository<Playlist>,
    @InjectRepository(Artist)
    private readonly artistRepository: Repository<Artist>,
    private readonly songsService: SongsService,
    private readonly albumsService: AlbumsService,
    private readonly artistsService: ArtistsService,
  ) {}

  async me(user: UserPayload) {
    const person = await this.userRepository.findOne({
      where: {
        id: user.sub,
      },
      relations: {
        playlists: {
          songs: true,
        },
        likedSongs: {
          artists: true,
          album: true,
        },
        likedAlbums: true,
        likedPlaylists: true,
        followedArtists: true,
        joinedRooms: true,
      },
    });

    if (!person) throw new NotFoundException('User not found');

    return person;
  }

  private readonly usernameCache = new Map<string, { available: boolean; timestamp: number }>();
  private readonly CACHE_TTL = 300000;

  async isUsernameAvailable(username: string): Promise<boolean> {
    const cached = this.usernameCache.get(username);
    const now = Date.now();
    if (cached && now - cached.timestamp < this.CACHE_TTL) {
      return cached.available;
    }

    const existingUser = await this.userRepository.findOne({
      where: { username },
    });
    const available = !existingUser;

    this.usernameCache.set(username, {
      available,
      timestamp: now,
    });

    if (this.usernameCache.size > 1000) {
      for (const [key, val] of this.usernameCache.entries()) {
        if (now - val.timestamp > this.CACHE_TTL) {
          this.usernameCache.delete(key);
        }
      }
    }

    return available;
  }

  async findAll(userId: string, query?: string, page = 1, limit = 10) {
    const qb = this.userRepository.createQueryBuilder('user');

    qb.where('user.id != :id', { id: userId });

    if (query) {
      qb.andWhere('(user.username ILIKE :query OR user.name ILIKE :query)', {
        query: `%${query}%`,
      });
    }

    const total = await qb.getCount();
    const pageNum = Math.max(1, page);
    const limitNum = Math.max(1, limit);
    const skip = (pageNum - 1) * limitNum;

    qb.skip(skip).take(limitNum);

    const data = await qb.getMany();

    return {
      data,
      meta: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum),
      },
    };
  }

  async follow(userId: string, followeeId: string) {
    if (userId === followeeId) {
      throw new BadRequestException('You cannot follow yourself');
    }

    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { following: true },
    });

    const followee = await this.userRepository.findOne({
      where: { id: followeeId },
    });

    if (!user || !followee) {
      throw new NotFoundException('User not found');
    }

    if (!user.following.some((f) => f.id === followee.id)) {
      user.following.push(followee);
      await this.userRepository.save(user);
    }

    return { success: true };
  }

  async unfollow(userId: string, followeeId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { following: true },
    });

    const followee = await this.userRepository.findOne({
      where: { id: followeeId },
    });

    if (!user || !followee) {
      throw new NotFoundException('User not found');
    }

    user.following = user.following.filter((f) => f.id !== followee.id);
    await this.userRepository.save(user);

    return { success: true };
  }

  async getFollowers(userId: string, page = 1, limit = 10) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const qb = this.userRepository
      .createQueryBuilder('user')
      .innerJoin('user.following', 'following')
      .where('following.id = :userId', { userId });

    const total = await qb.getCount();
    const pageNum = Math.max(1, page);
    const limitNum = Math.max(1, limit);
    const skip = (pageNum - 1) * limitNum;

    const data = await qb.skip(skip).take(limitNum).getMany();

    return {
      data,
      meta: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum),
      },
    };
  }

  async getFollowing(userId: string, page = 1, limit = 10) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const qb = this.userRepository
      .createQueryBuilder('user')
      .innerJoin('user.followers', 'followers')
      .where('followers.id = :userId', { userId });

    const total = await qb.getCount();
    const pageNum = Math.max(1, page);
    const limitNum = Math.max(1, limit);
    const skip = (pageNum - 1) * limitNum;

    const data = await qb.skip(skip).take(limitNum).getMany();

    return {
      data,
      meta: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum),
      },
    };
  }

  async findOne(id: string) {
    if (id == undefined || id == null) {
      throw new BadRequestException();
    }

    const user = await this.userRepository.findOne({
      where: { id },
      relations: {
        playlists: true,
        likedSongs: {
          artists: true,
          album: true,
        },
        likedAlbums: true,
        likedPlaylists: true,
        followedArtists: true,
        joinedRooms: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    return user;
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    if (id == undefined || id == null) {
      throw new BadRequestException();
    }

    const user = await this.findOne(id);

    if (updateUserDto.username && updateUserDto.username !== user.username) {
      const existingUser = await this.userRepository.findOne({
        where: { username: updateUserDto.username },
      });
      if (existingUser) {
        throw new ConflictException('Username is already taken.');
      }
    }

    Object.assign(user, {
      ...updateUserDto,
      updatedAt: new Date(),
    });

    return this.userRepository.save(user);
  }

  async remove(id: string) {
    if (id == undefined || id == null) {
      throw new BadRequestException();
    }

    const user = await this.userRepository.findOne({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException('User not found.');
    }

    await this.sessionRepository.delete({ userId: id });
    await this.userRepository.delete(id);
  }

  async likeSong(userId: string, songId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { likedSongs: true },
    });
    if (!user) throw new NotFoundException('User not found');

    let song = await this.songRepository.findOne({ where: { id: songId } });
    if (!song) {
      const songData = await this.songsService.findById(songId);
      if (!songData) throw new NotFoundException('Song not found');

      song = await this.songsService.findOrCreate(songData.id, songData.title, {
        duration: songData.duration,
        thumbnail: songData.thumbnail,
        year: songData.year,
        artistIds: songData.artists.map((a: any) => a.id),
      } as any);
    }

    if (!user.likedSongs.some((s) => s.id === song.id)) {
      user.likedSongs.push(song);
      await this.userRepository.save(user);
    }
    return { success: true };
  }

  async unlikeSong(userId: string, songId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { likedSongs: true },
    });
    if (!user) throw new NotFoundException('User not found');

    user.likedSongs = user.likedSongs.filter((s) => s.id !== songId);
    await this.userRepository.save(user);
    return { success: true };
  }

  async likeAlbum(userId: string, albumId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { likedAlbums: true },
    });
    if (!user) throw new NotFoundException('User not found');

    let album = await this.albumRepository.findOne({ where: { id: albumId } });
    if (!album) {
      const albumData = await this.albumsService.findById(albumId);
      if (!albumData) throw new NotFoundException('Album not found');

      album = await this.albumsService.findOrCreate(albumData.id, albumData.title, {
        type: albumData.type,
        thumbnail: albumData.thumbnail,
        isExplicit: albumData.isExplicit,
        description: albumData.description,
        year: albumData.year,
        trackCount: albumData.trackCount,
        durationSeconds: albumData.durationSeconds,
        artistIds: albumData.artists.map((a: any) => a.id),
      } as any);
    }

    if (!user.likedAlbums.some((a) => a.id === album.id)) {
      user.likedAlbums.push(album);
      await this.userRepository.save(user);
    }
    return { success: true };
  }

  async unlikeAlbum(userId: string, albumId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { likedAlbums: true },
    });
    if (!user) throw new NotFoundException('User not found');

    user.likedAlbums = user.likedAlbums.filter((a) => a.id !== albumId);
    await this.userRepository.save(user);
    return { success: true };
  }

  async followRoom(userId: string, roomId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { joinedRooms: true },
    });
    if (!user) return;

    const room = await this.roomRepository.findOne({ where: { id: roomId } });
    if (!room) throw new NotFoundException('Room not found');

    if (!user.joinedRooms.some((r) => r.id === room.id)) {
      user.joinedRooms.push(room);
      await this.userRepository.save(user);
    }
    return { success: true };
  }

  async unfollowRoom(userId: string, roomId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { joinedRooms: true },
    });
    if (!user) return;

    user.joinedRooms = user.joinedRooms.filter((r) => r.id !== roomId);
    await this.userRepository.save(user);
    return { success: true };
  }

  async followArtist(userId: string, artistId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { followedArtists: true },
    });
    if (!user) throw new NotFoundException('User not found');

    let artist = await this.artistRepository.findOne({ where: { id: artistId } });
    if (!artist) {
      const artistData = await this.artistsService.findById(artistId);
      if (!artistData) throw new NotFoundException('Artist not found');

      artist = await this.artistsService.findOrCreate(artistData.id, artistData.name, {
        thumbnail: artistData.thumbnail,
        description: artistData.description,
        subscribers: artistData.subscribers,
        views: artistData.views,
        monthlyListeners: artistData.monthlyListeners,
      } as any);
    }

    if (!user.followedArtists.some((a) => a.id === artist.id)) {
      user.followedArtists.push(artist);
      await this.userRepository.save(user);
    }
    return { success: true };
  }

  async unfollowArtist(userId: string, artistId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { followedArtists: true },
    });
    if (!user) throw new NotFoundException('User not found');

    user.followedArtists = user.followedArtists.filter((a) => a.id !== artistId);
    await this.userRepository.save(user);
    return { success: true };
  }

  async likePlaylist(userId: string, playlistId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { likedPlaylists: true },
    });
    if (!user) throw new NotFoundException('User not found');

    const playlist = await this.playlistRepository.findOne({ where: { id: playlistId } });
    if (!playlist) throw new NotFoundException('Playlist not found');

    if (!user.likedPlaylists.some((p) => p.id === playlist.id)) {
      user.likedPlaylists.push(playlist);
      await this.userRepository.save(user);
    }
    return { success: true };
  }

  async unlikePlaylist(userId: string, playlistId: string) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      relations: { likedPlaylists: true },
    });
    if (!user) throw new NotFoundException('User not found');

    user.likedPlaylists = user.likedPlaylists.filter((p) => p.id !== playlistId);
    await this.userRepository.save(user);
    return { success: true };
  }
}
