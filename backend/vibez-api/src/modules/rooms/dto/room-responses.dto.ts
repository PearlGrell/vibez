import { Song } from 'src/modules/songs/entities/song.entity';
import { User } from 'src/modules/users/entities/user.entity';
import { Room } from '../entities/room.entity';
import { QueueItem } from '../entities/queue-item.entity';

export interface RoomJoinResponseDto {
  success: boolean;
  room: Room;
  participants: number;
  participantsInitials: string[];
}

export interface RoomLeaveResponseDto {
  success: boolean;
  roomId: string;
}


export interface RoomDetailsResponseDto {
  room: Room;
  participants: number;
  participantsInitials: string[];
}

export interface RoomsResponseDto {
  rooms: RoomSummaryDto[];
  total: number;
  limit: number;
  page: number;
  totalPages: number;
}

export interface RoomSummaryDto {
  id: string;
  name: string;
  description: string;
  tags: string[];
  participants: number;
  currentSong: Song | null;
  currentDj: User | null;
  createdBy: User | null;
  playing: boolean;
  startedAt: Date | null;
}

export interface QueueResponseDto {
  queue: QueueItem[];
}

export interface QueueItemResponseDto {
  item: QueueItem;
}

export interface DjResponseDto {
  room: Room;
  participants: number;
  participantsInitials: string[];
}

export interface SongRequestResponseDto {
  roomId: string;
  song: Song;
  requestedBy: User;
}
