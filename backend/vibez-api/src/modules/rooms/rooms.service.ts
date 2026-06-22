import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Room } from './entities/room.entity';
import { User } from '../users/entities/user.entity';
import { Repository } from 'typeorm';
import { UpdateRoomDto } from './dto/update-room.dto';

@Injectable()
export class RoomsService {
  constructor(
    @InjectRepository(Room)
    private readonly roomRepo: Repository<Room>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async get() {
    return await this.roomRepo.find({
      where: {
        private: false
      }
    });
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
    return await this.roomRepo.save(room);
  }

  async delete(id: string, userId: string) {
    const room = await this.getById(id);
    if (room.createdById !== userId) {
      throw new ForbiddenException('You do not have permission to delete this room');
    }
    await this.roomRepo.remove(room);
    return { success: true };
  }

  async addUserToRoom(userId: string, roomId: string) {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      relations: { joinedRooms: true },
    });
    if (!user) return;

    const room = await this.roomRepo.findOne({ where: { id: roomId } });
    if (!room) return;

    if (!user.joinedRooms.some((r) => r.id === room.id)) {
      user.joinedRooms.push(room);
      await this.userRepo.save(user);
    }
  }

  async removeUserFromRoom(userId: string, roomId: string) {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      relations: { joinedRooms: true },
    });
    if (!user) return;

    user.joinedRooms = user.joinedRooms.filter((r) => r.id !== roomId);
    await this.userRepo.save(user);
  }

  async removeUserFromAllRooms(userId: string) {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      relations: { joinedRooms: true },
    });
    if (!user) return;

    user.joinedRooms = [];
    await this.userRepo.save(user);
  }
}
