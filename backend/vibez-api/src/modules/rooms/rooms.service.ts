import { ForbiddenException, Injectable, NotFoundException, OnModuleDestroy } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Room } from './entities/room.entity';
import { User } from '../users/entities/user.entity';
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
      where: {
        private: false,
      },
      take: limit,
    });
  }

  async getAll() {
    return await this.roomRepo.find();
  }

  async getById(id: string) {
    const room = await this.roomRepo.findOne({
      where: {
        id: id,
      },
    });
    if (!room || room === undefined) {
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


}
