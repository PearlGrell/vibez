import { Song } from "src/modules/songs/entities/song.entity";
import { User } from "src/modules/users/entities/user.entity";

export interface RoomJoinResponseDto {
  success: boolean;
  roomId: string;
  participants: number;
  currentSong?: Song | null;
  currentDj?: User | null;
  playing?: boolean | null;
  startedAt?: Date | null;
}

export interface RoomLeaveResponseDto {
  success: boolean;
  roomId: string;
}

export interface RoomSyncResponseDto {
  participants: number;
  currentSong?: Song | null;
  currentDj?: User | null;
  playing?: boolean | null;
  startedAt?: Date | null;
}

export interface RoomsResponseDto {
  rooms: RoomSummaryDto[];
}

interface RoomSummaryDto {
  id: string;
  name: string;
  participants: number;
  currentSongId?: Song | null;
  currentDj?: User | null;
  playing?: boolean | null;
  startedAt?: Date | null;
}