import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { ILike, Repository } from 'typeorm';
import { Playlist } from '../entities/playlist.entity';
import { Song } from '../../songs/entities/song.entity';
import { SongsService } from '../../songs/songs.service';

@Injectable()
export class PlaylistsService {
  constructor(
    @InjectRepository(Playlist)
    private readonly playlistRepository: Repository<Playlist>,
    @InjectRepository(Song)
    private readonly songRepository: Repository<Song>,
    private readonly songsService: SongsService,
  ) {}

  async create(
    userId: string,
    name: string,
    isPrivate: boolean,
    tags: string[],
    thumbnail?: string | null,
    description?: string | null,
  ) {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }

    const playlist = await this.playlistRepository.save(
      this.playlistRepository.create({
        name,
        description,
        private: isPrivate,
        tags,
        thumbnail,
        createdById: userId,
      }),
    );

    return playlist;
  }

  async update(
    userId: string,
    playlistId: string,
    name?: string,
    isPrivate?: boolean,
    tags?: string[],
    thumbnail?: string | null,
    description?: string | null,
  ) {
    if (!userId) {
      throw new BadRequestException('User ID is required');
    }

    const playlist = await this.playlistRepository.findOne({
      where: {
        id: playlistId,
      },
    });

    if (!playlist) {
      throw new NotFoundException('Playlist not found');
    }

    if (playlist.createdById !== userId) {
      throw new ForbiddenException('You do not have permission to modify this playlist');
    }

    if (name !== undefined) {
      playlist.name = name;
    }
    if (isPrivate !== undefined) {
      playlist.private = isPrivate;
    }
    if (tags !== undefined) {
      playlist.tags = tags;
    }
    if (thumbnail !== undefined) {
      playlist.thumbnail = thumbnail;
    }
    if (description !== undefined) {
      playlist.description = description;
    }

    return await this.playlistRepository.save(playlist);
  }

  async findOne(playlistId: string, userId: string) {
    const playlist = await this.playlistRepository.findOne({
      where: { id: playlistId },
      relations: {
        songs: {
          artists: true,
          album: true,
        },
      },
    });

    if (!playlist) {
      throw new NotFoundException('Playlist not found');
    }

    if (playlist.private && playlist.createdById !== userId) {
      throw new ForbiddenException('This playlist is private');
    }

    return playlist;
  }

  async getPlaylists(limit?: number) {
    return await this.playlistRepository.find({
      where: {
        private: false,
      },
      take: limit,
    });
  }

  async addSong(userId: string, playlistId: string, songId: string) {
    const playlist = await this.playlistRepository.findOne({
      where: { id: playlistId },
      relations: { songs: true },
    });

    if (!playlist) {
      throw new NotFoundException('Playlist not found');
    }

    if (playlist.createdById !== userId) {
      throw new ForbiddenException('You do not have permission to modify this playlist');
    }

    let song = await this.songRepository.findOne({ where: { id: songId } });
    if (!song) {
      const songData = await this.songsService.findById(songId);
      if (!songData) {
        throw new NotFoundException('Song not found');
      }
      song = await this.songsService.findOrCreate(songData.id, songData.title, {
        duration: songData.duration,
        thumbnail: songData.thumbnail,
        year: songData.year,
        artistIds: songData.artists?.map((a: any) => a.id) || [],
      } as any);
    }

    if (!playlist.songs) {
      playlist.songs = [];
    }

    if (!playlist.songs.some((s) => s.id === song.id)) {
      playlist.songs.push(song);
      await this.playlistRepository.save(playlist);
    }

    return playlist;
  }
}
