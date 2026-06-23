export interface RoomJoinResponseDto {
  success: boolean;
  roomId: string;
  participants: number;
  currentSongId?: string | null;
  playing?: boolean | null;
  startedAt?: Date | null;
}

export interface RoomLeaveResponseDto {
  success: boolean;
  roomId: string;
}

export interface RoomSyncResponseDto {
  participants: number;
  currentSongId?: string | null;
  playing?: boolean | null;
  startedAt?: Date | null;
}
