import { ForbiddenException, Injectable, NotFoundException, OnModuleDestroy } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Room } from './entities/room.entity';
import { QueueItem } from './entities/queue-item.entity';
import { User } from '../users/entities/user.entity';
import { Song } from '../songs/entities/song.entity';
import { ILike, Repository } from 'typeorm';
import { UpdateRoomDto } from './dto/update-room.dto';

interface CacheItem<T> {
  value: T;
  expiry: number;
}

@Injectable()
export class RoomsService implements OnModuleDestroy {
  private activeRoomsCache = new Map<string, CacheItem<Room>>();
  private readonly CACHE_TTL = 1000 * 60 * 5; // 5 minutes
  private cleanupInterval: NodeJS.Timeout;

  constructor(
    @InjectRepository(Room)
    private readonly roomRepo: Repository<Room>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(QueueItem)
    private readonly queueRepo: Repository<QueueItem>,
    @InjectRepository(Song)
    private readonly songRepo: Repository<Song>,
  ) {
    this.cleanupInterval = setInterval(() => {
      const now = Date.now();
      for (const [id, item] of this.activeRoomsCache.entries()) {
        if (item.expiry <= now) {
          this.activeRoomsCache.delete(id);
        }
      }
    }, 1000 * 60 * 10);
  }

  onModuleDestroy() {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }
  }

  async get(limit?: number) {
    return await this.roomRepo.find({
      where: { private: false },
      relations: { currentDj: true, currentSong: { artists: true }, createdBy: true },
      take: limit,
    });
  }

  async getAll() {
    return await this.roomRepo.find();
  }

  async getSongById(id: string) {
    const song = await this.songRepo.findOne({ where: { id }, relations: { artists: true } });
    if (!song) throw new NotFoundException('Song not found');
    return song;
  }

  async getUserById(id: string) {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async getById(id: string) {
    const room = await this.roomRepo.findOne({
      where: { id },
      relations: { currentDj: true, currentSong: { artists: true }, createdBy: true },
    });
    if (!room) {
      throw new NotFoundException();
    }
    return room;
  }

  async getActiveRoom(id: string) {
    const cached = this.activeRoomsCache.get(id);
    if (cached && cached.expiry > Date.now()) {
      return cached.value;
    }
    const room = await this.getById(id);
    this.activeRoomsCache.set(id, { value: room, expiry: Date.now() + this.CACHE_TTL });
    return room;
  }

  async getByCreator(userId: string) {
    return await this.roomRepo.find({
      where: {
        createdById: userId,
      },
    });
  }

  async create(name: string, description: string, tags: string[], isPrivate: boolean, userId: string) {
    const room = this.roomRepo.create({
      name,
      description,
      tags,
      private: isPrivate,
      createdById: userId,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    return await this.roomRepo.save(room);
  }

  async update(id: string, updateRoomDto: UpdateRoomDto, userId: string) {
    const room = await this.getById(id);
    if (room.createdById !== userId) {
      throw new ForbiddenException('You do not have permission to update this room');
    }
    Object.assign(room, updateRoomDto);
    room.updatedAt = new Date();
    const updated = await this.roomRepo.save(room);
    this.activeRoomsCache.set(id, { value: updated, expiry: Date.now() + this.CACHE_TTL });
    return updated;
  }

  async delete(id: string, userId: string) {
    const room = await this.getById(id);
    if (room.createdById !== userId) {
      throw new ForbiddenException('You do not have permission to delete this room');
    }
    await this.roomRepo.remove(room);
    this.activeRoomsCache.delete(id);
    return { success: true };
  }

  async getQueue(roomId: string) {
    return await this.queueRepo.find({
      where: { roomId },
      relations: { song: { artists: true }, addedBy: true },
      order: { position: 'ASC', addedAt: 'ASC' },
    });
  }

  async addSongToQueue(roomId: string, songId: string, userId: string) {
    const song = await this.songRepo.findOne({
      where: { id: songId },
      relations: { artists: true },
    });
    if (!song) {
      throw new NotFoundException('Song not found');
    }

    const lastItem = await this.queueRepo.findOne({
      where: { roomId },
      order: { position: 'DESC' },
    });

    const item = this.queueRepo.create({
      roomId,
      songId,
      addedById: userId,
      position: (lastItem?.position ?? -1) + 1,
    });

    const saved = await this.queueRepo.save(item);
    return (await this.queueRepo.findOne({
      where: { id: saved.id },
      relations: { song: { artists: true }, addedBy: true },
    }))!;
  }

  async removeSongFromQueue(roomId: string, queueItemId: string, userId: string) {
    const item = await this.queueRepo.findOne({
      where: { id: queueItemId, roomId },
      relations: { song: { artists: true }, addedBy: true },
    });
    if (!item) {
      throw new NotFoundException('Queue item not found');
    }
    await this.queueRepo.remove(item);
    return item;
  }

  async isDj(roomId: string, userId: string): Promise<boolean> {
    const room = await this.getById(roomId);
    return room.currentDj?.id === userId;
  }

  async joinAsDj(roomId: string, userId: string) {
    const room = await this.getById(roomId);
    if (room.currentDj) {
      throw new ForbiddenException('Room already has a DJ');
    }
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    room.currentDj = user;
    room.updatedAt = new Date();
    const updated = await this.roomRepo.save(room);
    this.activeRoomsCache.set(roomId, { value: updated, expiry: Date.now() + this.CACHE_TTL });
    return updated;
  }

  async leaveAsDj(roomId: string, userId: string) {
    const room = await this.getById(roomId);
    if (!room.currentDj || room.currentDj.id !== userId) {
      throw new ForbiddenException('You are not the current DJ');
    }
    room.currentDj = null;
    room.updatedAt = new Date();
    const updated = await this.roomRepo.save(room);
    this.activeRoomsCache.set(roomId, { value: updated, expiry: Date.now() + this.CACHE_TTL });
    return updated;
  }

  async assignDj(roomId: string, currentDjId: string, targetUserId: string) {
    const room = await this.getById(roomId);
    if (!room.currentDj || room.currentDj.id !== currentDjId) {
      throw new ForbiddenException('Only the current DJ can assign a new DJ');
    }
    const user = await this.userRepo.findOne({ where: { id: targetUserId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    room.currentDj = user;
    room.updatedAt = new Date();
    const updated = await this.roomRepo.save(room);
    this.activeRoomsCache.set(roomId, { value: updated, expiry: Date.now() + this.CACHE_TTL });
    return updated;
  }

  async play(roomId: string, userId: string) {
    const room = await this.getById(roomId);
    if (!room.currentDj || room.currentDj.id !== userId) {
      throw new ForbiddenException('Only the DJ can control playback');
    }
    room.playing = true;
    room.startedAt = new Date();
    room.updatedAt = new Date();
    const updated = await this.roomRepo.save(room);
    this.activeRoomsCache.set(roomId, { value: updated, expiry: Date.now() + this.CACHE_TTL });
    return updated;
  }

  async pause(roomId: string, userId: string) {
    const room = await this.getById(roomId);
    if (!room.currentDj || room.currentDj.id !== userId) {
      throw new ForbiddenException('Only the DJ can control playback');
    }
    room.playing = false;
    room.updatedAt = new Date();
    const updated = await this.roomRepo.save(room);
    this.activeRoomsCache.set(roomId, { value: updated, expiry: Date.now() + this.CACHE_TTL });
    return updated;
  }

  async changeSong(roomId: string, songId: string, userId: string) {
    const room = await this.getById(roomId);
    if (!room.currentDj || room.currentDj.id !== userId) {
      throw new ForbiddenException('Only the DJ can change songs');
    }
    const song = await this.songRepo.findOne({ where: { id: songId }, relations: { artists: true } });
    if (!song) {
      throw new NotFoundException('Song not found');
    }
    room.currentSong = song;
    room.playing = true;
    room.startedAt = new Date();
    room.updatedAt = new Date();
    const updated = await this.roomRepo.save(room);
    this.activeRoomsCache.set(roomId, { value: updated, expiry: Date.now() + this.CACHE_TTL });
    return updated;
  }

  async autoAssignDj(roomId: string, participantUserIds: string[]) {
    const room = await this.getById(roomId);
    if (participantUserIds.length === 0) {
      room.currentDj = null;
      room.playing = false;
      room.currentSong = null;
      room.startedAt = null;
      room.updatedAt = new Date();
      const updated = await this.roomRepo.save(room);
      this.activeRoomsCache.set(roomId, { value: updated, expiry: Date.now() + this.CACHE_TTL });
      return updated;
    }
    const randomId = participantUserIds[Math.floor(Math.random() * participantUserIds.length)];
    const user = await this.userRepo.findOne({ where: { id: randomId } });
    if (!user) {
      return room;
    }
    room.currentDj = user;
    room.updatedAt = new Date();
    const updated = await this.roomRepo.save(room);
    this.activeRoomsCache.set(roomId, { value: updated, expiry: Date.now() + this.CACHE_TTL });
    return updated;
  }
}
