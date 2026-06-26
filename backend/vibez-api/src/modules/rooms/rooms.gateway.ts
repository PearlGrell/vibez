import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  WsException,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { RoomsService } from './rooms.service';
import { JwtService } from '@nestjs/jwt';
import { UsePipes } from '@nestjs/common';
import { ZodPipe } from 'src/common/pipes/zod/zod.pipe';
import { type JoinRoomDto, joinRoomSchema } from './dto/join-room.dto';
import { type LeaveRoomDto, leaveRoomSchema } from './dto/leave-room.dto';
import {
  type AddSongDto,
  addSongSchema,
  type RemoveSongDto,
  removeSongSchema,
  type RequestSongDto,
  requestSongSchema,
  type AssignDjDto,
  assignDjSchema,
} from './dto/queue.dto';
import { RoomEvents } from './constants/room-events';
import {
  type RoomJoinResponseDto,
  type RoomLeaveResponseDto,
  type RoomDetailsResponseDto,
  type RoomsResponseDto,
  type QueueResponseDto,
  type QueueItemResponseDto,
  type DjResponseDto,
  type SongRequestResponseDto,
} from './dto/room-responses.dto';
import { Room } from './entities/room.entity';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class RoomsGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  constructor(
    private readonly roomService: RoomsService,
    private readonly jwtService: JwtService,
  ) {}

  @WebSocketServer()
  server: Server;

  afterInit(server: Server) {
    server.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth?.token;
        if (!token) {
          return next(new Error('Authentication error'));
        }
        const payload = await this.jwtService.verifyAsync(token);
        socket.data.user = payload;
        try {
          const user = await this.roomService.getUserById(payload.sub);
          socket.data.user.name = user.name;
        } catch {}
        next();
      } catch {
        next(new Error('Authentication error'));
      }
    });

    server.on('connection', (socket) => {
      socket.on('disconnecting', () => {
        this.handleDisconnecting(socket);
      });
    });
  }

  handleConnection(client: Socket) {}

  handleDisconnect(client: Socket) {}

  private async handleDisconnecting(client: Socket) {
    for (const r of client.rooms) {
      if (!r.startsWith('room:')) continue;
      const roomId = r.replace('room:', '');
      try {
        const wasDj = await this.roomService.isDj(roomId, client.data.user.sub);
        const participantsAfter = Math.max(0, this.getParticipantCount(roomId) - 1);
        const freshRoom = await (async () => {
          if (wasDj || participantsAfter === 0) {
            const participantIds = await this.getParticipantUserIds(roomId, client.id);
            return this.roomService.autoAssignDj(roomId, participantIds, client.data.user.sub);
          }
          return this.roomService.getById(roomId);
        })();
        this.broadcastStateUpdate(r, freshRoom);
        this.broadcastPlaybackQueue(roomId);
        this.server.to(r).emit(RoomEvents.USER_LEFT, {
          userId: client.data.user.sub,
          room: freshRoom,
          participants: participantsAfter,
          participantsInitials: this.getParticipantInitials(roomId, client.id),
        });
        this.broadcastRoomSummary(freshRoom, participantsAfter, client.id);
      } catch {}
    }
  }

  private getParticipantCount(roomId: string): number {
    return this.server.sockets.adapter.rooms.get(`room:${roomId}`)?.size ?? 0;
  }

  private async getParticipantUserIds(roomId: string, excludeSocketId?: string): Promise<string[]> {
    const socketIds = this.server.sockets.adapter.rooms.get(`room:${roomId}`);
    if (!socketIds) return [];
    const ids: string[] = [];
    for (const sid of socketIds) {
      if (sid === excludeSocketId) continue;
      const s = this.server.sockets.sockets.get(sid);
      if (s?.data?.user?.sub) {
        ids.push(s.data.user.sub);
      }
    }
    return ids;
  }

  private getParticipantInitials(roomId: string, excludeSocketId?: string): string[] {
    const socketIds = this.server.sockets.adapter.rooms.get(`room:${roomId}`);
    if (!socketIds) return [];
    const initials: string[] = [];
    for (const sid of socketIds) {
      if (sid === excludeSocketId) continue;
      const s = this.server.sockets.sockets.get(sid);
      const name = s?.data?.user?.name;
      if (name) {
        initials.push(name[0].toUpperCase());
      }
    }
    return initials;
  }

  private broadcastStateUpdate(roomName: string, room: Room) {
    const roomId = roomName.startsWith('room:') ? roomName.replace('room:', '') : roomName;
    this.server.to(`room:${roomId}`).emit(RoomEvents.STATE_UPDATE, {
      room,
      participants: this.getParticipantCount(roomId),
      participantsInitials: this.getParticipantInitials(roomId),
    });
  }

  private async broadcastPlaybackQueue(roomId: string) {
    const id = roomId.startsWith('room:') ? roomId.replace('room:', '') : roomId;
    const queue = await this.roomService.getQueue(id);
    this.server.emit(RoomEvents.QUEUE_UPDATE, { roomId: id, queue });
  }

  private broadcastRoomSummary(room: Room, participantOverride?: number, excludeSocketId?: string) {
    const participants = participantOverride ?? this.getParticipantCount(room.id);
    const initials = this.getParticipantInitials(room.id, excludeSocketId).slice(0, 5);
    this.server.emit(RoomEvents.ROOMS_UPDATE, {
      id: room.id,
      name: room.name,
      description: room.description,
      tags: room.tags,
      currentDj: room.currentDj,
      createdBy: room.createdBy,
      participants,
      participantsInitials: initials,
      currentSong: room.currentSong,
      playing: room.playing,
      startedAt: room.startedAt,
    });
  }

  private async ensureDj(roomId: string, userId: string) {
    const isDj = await this.roomService.isDj(roomId, userId);
    if (!isDj) {
      throw new WsException({ code: 'NOT_DJ', message: 'Only the DJ can perform this action' });
    }
  }

  private async ensureNotDj(roomId: string, userId: string) {
    const isDj = await this.roomService.isDj(roomId, userId);
    if (isDj) {
      throw new WsException({ code: 'IS_DJ', message: 'The DJ cannot perform this action' });
    }
  }

  // ── Room listing & details ──

  @SubscribeMessage(RoomEvents.ROOMS)
  async listRooms(
    @ConnectedSocket() client: Socket,
    @MessageBody() data?: { limit?: number; page?: number; sort?: string },
  ): Promise<RoomsResponseDto> {
    const limit = Math.min(Math.max(data?.limit ?? 20, 1), 100);
    const page = Math.max(data?.page ?? 1, 1);

    const allRooms = await this.roomService.get();

    let enriched = allRooms.map((room) => ({
      id: room.id,
      name: room.name,
      description: room.description,
      tags: room.tags,
      currentDj: room.currentDj,
      createdBy: room.createdBy,
      participants: this.getParticipantCount(room.id),
      currentSong: room.currentSong,
      playing: room.playing,
      startedAt: room.startedAt,
    }));

    if (data?.sort === 'trending') {
      enriched.sort((a, b) => b.participants - a.participants);
    } else if (data?.sort === 'newest') {
      enriched.sort((a, b) => {
        const aTime = a.startedAt ? new Date(a.startedAt).getTime() : 0;
        const bTime = b.startedAt ? new Date(b.startedAt).getTime() : 0;
        return bTime - aTime;
      });
    } else if (data?.sort === 'related') {
      const user = await this.roomService.getUserById(client.data.user.sub);
      const userTags = new Set(user.tags ?? []);
      enriched.sort((a, b) => {
        const aScore = a.tags.filter((t) => userTags.has(t)).length;
        const bScore = b.tags.filter((t) => userTags.has(t)).length;
        return bScore - aScore;
      });
    }

    const total = enriched.length;
    const totalPages = Math.ceil(total / limit);
    const offset = (page - 1) * limit;
    const rooms = enriched.slice(offset, offset + limit);

    return { rooms, total, limit, page, totalPages };
  }

  @SubscribeMessage(RoomEvents.DETAILS)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async roomDetails(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: JoinRoomDto,
  ): Promise<RoomDetailsResponseDto> {
    const room = await this.roomService.getById(data.roomId);
    return {
      room,
      participants: this.getParticipantCount(room.id),
      participantsInitials: this.getParticipantInitials(room.id),
    };
  }

  // ── Join & leave room ──

  @SubscribeMessage(RoomEvents.JOIN)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async joinRoom(@ConnectedSocket() client: Socket, @MessageBody() data: JoinRoomDto): Promise<RoomJoinResponseDto> {
    const room = await this.roomService.getById(data.roomId);
    const roomName = `room:${room.id}`;

    if (client.rooms.has(roomName)) {
      return {
        success: true,
        room,
        participants: this.getParticipantCount(room.id),
        participantsInitials: this.getParticipantInitials(room.id),
      };
    }

    for (const r of client.rooms) {
      if (r.startsWith('room:') && r !== roomName) {
        const oldRoomId = r.replace('room:', '');
        const wasDj = await this.roomService.isDj(oldRoomId, client.data.user.sub);
        await client.leave(r);
        const oldRoom = await (async () => {
          if (wasDj || this.getParticipantCount(oldRoomId) === 0) {
            const participantIds = await this.getParticipantUserIds(oldRoomId);
            return this.roomService.autoAssignDj(oldRoomId, participantIds, client.data.user.sub);
          }
          return this.roomService.getById(oldRoomId);
        })();
        this.broadcastStateUpdate(r, oldRoom);
        this.broadcastPlaybackQueue(oldRoomId);
        this.server.to(r).emit(RoomEvents.USER_LEFT, {
          userId: client.data.user.sub,
          room: oldRoom,
          participants: this.getParticipantCount(oldRoomId),
          participantsInitials: this.getParticipantInitials(oldRoomId),
        });
        this.broadcastRoomSummary(oldRoom);
      }
    }

    await client.join(roomName);
    this.broadcastStateUpdate(roomName, room);
    this.broadcastPlaybackQueue(room.id);
    this.server.to(roomName).emit(RoomEvents.USER_JOINED, {
      userId: client.data.user.sub,
      room,
      participants: this.getParticipantCount(room.id),
      participantsInitials: this.getParticipantInitials(room.id),
    });
    this.broadcastRoomSummary(room);

    return {
      success: true,
      room,
      participants: this.getParticipantCount(room.id),
      participantsInitials: this.getParticipantInitials(room.id),
    };
  }

  @SubscribeMessage(RoomEvents.LEAVE)
  @UsePipes(new ZodPipe(leaveRoomSchema))
  async leaveRoom(@ConnectedSocket() client: Socket, @MessageBody() data: LeaveRoomDto): Promise<RoomLeaveResponseDto> {
    const room = await this.roomService.getActiveRoom(data.roomId);
    if (!room) {
      throw new WsException({ code: 'ROOM_NOT_FOUND', message: 'Room not found' });
    }

    const roomName = `room:${room.id}`;
    const wasDj = await this.roomService.isDj(room.id, client.data.user.sub);

    await client.leave(roomName);

    const freshRoom = await (async () => {
      if (wasDj || this.getParticipantCount(room.id) === 0) {
        const participantIds = await this.getParticipantUserIds(room.id);
        return this.roomService.autoAssignDj(room.id, participantIds, client.data.user.sub);
      }
      return this.roomService.getById(room.id);
    })();

    this.broadcastStateUpdate(roomName, freshRoom);
    this.broadcastPlaybackQueue(room.id);
    this.server.to(roomName).emit(RoomEvents.USER_LEFT, {
      userId: client.data.user.sub,
      room: freshRoom,
      participants: this.getParticipantCount(room.id),
    });
    this.broadcastRoomSummary(freshRoom);

    return { success: true, roomId: room.id };
  }

  // ── Queue (DJ only for add/remove, anyone except DJ for request) ──

  @SubscribeMessage(RoomEvents.QUEUE)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async getQueue(@ConnectedSocket() client: Socket, @MessageBody() data: JoinRoomDto): Promise<QueueResponseDto> {
    await this.roomService.getActiveRoom(data.roomId);
    const queue = await this.roomService.getQueue(data.roomId);
    return { queue };
  }

  @SubscribeMessage(RoomEvents.ADD_SONG)
  @UsePipes(new ZodPipe(addSongSchema))
  async addSong(@ConnectedSocket() client: Socket, @MessageBody() data: AddSongDto): Promise<QueueItemResponseDto> {
    try {
      await this.ensureDj(data.roomId, client.data.user.sub);
      const item = await this.roomService.addSongToQueue(data.roomId, data.songId, client.data.user.sub);

      this.broadcastPlaybackQueue(data.roomId);
      return { item };
    } catch (e) {
      console.error(e);
      throw e;
    }
  }

  @SubscribeMessage(RoomEvents.REMOVE_SONG)
  @UsePipes(new ZodPipe(removeSongSchema))
  async removeSong(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: RemoveSongDto,
  ): Promise<QueueItemResponseDto> {
    await this.ensureDj(data.roomId, client.data.user.sub);

    const item = await this.roomService.removeSongFromQueue(data.roomId, data.queueItemId, client.data.user.sub);

    this.broadcastPlaybackQueue(data.roomId);
    return { item };
  }

  @SubscribeMessage(RoomEvents.REQUEST_SONG)
  @UsePipes(new ZodPipe(requestSongSchema))
  async requestSong(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: RequestSongDto,
  ): Promise<SongRequestResponseDto> {
    await this.ensureNotDj(data.roomId, client.data.user.sub);

    const song = await this.roomService.getSongById(data.songId);
    const user = await this.roomService.getUserById(client.data.user.sub);

    const payload: SongRequestResponseDto = { roomId: data.roomId, song, requestedBy: user };
    this.server.to(`room:${data.roomId}`).emit(RoomEvents.SONG_REQUESTED, payload);
    return payload;
  }

  // ── Playback (DJ only) ──

  @SubscribeMessage(RoomEvents.STOP_SONG)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async play(@ConnectedSocket() client: Socket, @MessageBody() data: JoinRoomDto): Promise<DjResponseDto> {
    const room = await this.roomService.stop(data.roomId, client.data.user.sub);
    this.broadcastStateUpdate(`room:${data.roomId}`, room);
    this.broadcastRoomSummary(room);
    return { room, participants: this.getParticipantCount(room.id), participantsInitials: this.getParticipantInitials(room.id) };
  }

  @SubscribeMessage(RoomEvents.SONG_CHANGED)
  @UsePipes(new ZodPipe(addSongSchema))
  async changeSong(@ConnectedSocket() client: Socket, @MessageBody() data: AddSongDto): Promise<DjResponseDto> {
    const room = await this.roomService.changeSong(data.roomId, data.songId, client.data.user.sub);
    this.broadcastStateUpdate(`room:${data.roomId}`, room);
    this.broadcastPlaybackQueue(data.roomId);
    this.broadcastRoomSummary(room);
    return { room, participants: this.getParticipantCount(room.id), participantsInitials: this.getParticipantInitials(room.id) };
  }

  // ── DJ management ──

  @SubscribeMessage(RoomEvents.REQUEST_DJ)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async requestDj(@ConnectedSocket() client: Socket, @MessageBody() data: JoinRoomDto): Promise<{ success: boolean }> {
    const user = await this.roomService.getUserById(client.data.user.sub);
    this.server.to(`room:${data.roomId}`).emit(RoomEvents.DJ_REQUESTED, { user });
    return { success: true };
  }

  @SubscribeMessage(RoomEvents.JOIN_DJ)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async joinDj(@ConnectedSocket() client: Socket, @MessageBody() data: JoinRoomDto): Promise<DjResponseDto> {
    const room = await this.roomService.joinAsDj(data.roomId, client.data.user.sub);
    this.broadcastStateUpdate(`room:${data.roomId}`, room);
    this.broadcastRoomSummary(room);
    return { room, participants: this.getParticipantCount(room.id), participantsInitials: this.getParticipantInitials(room.id) };
  }

  @SubscribeMessage(RoomEvents.LEAVE_DJ)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async leaveDj(@ConnectedSocket() client: Socket, @MessageBody() data: JoinRoomDto): Promise<DjResponseDto> {
    await this.roomService.leaveAsDj(data.roomId, client.data.user.sub);
    const participantIds = await this.getParticipantUserIds(data.roomId);
    const updated = await this.roomService.autoAssignDj(data.roomId, participantIds, client.data.user.sub);
    this.broadcastStateUpdate(`room:${data.roomId}`, updated);
    this.broadcastRoomSummary(updated);
    return { room: updated, participants: this.getParticipantCount(updated.id), participantsInitials: this.getParticipantInitials(updated.id) };
  }

  @SubscribeMessage(RoomEvents.ASSIGN_DJ)
  @UsePipes(new ZodPipe(assignDjSchema))
  async assignDj(@ConnectedSocket() client: Socket, @MessageBody() data: AssignDjDto): Promise<DjResponseDto> {
    const room = await this.roomService.assignDj(data.roomId, client.data.user.sub, data.userId);
    this.broadcastStateUpdate(`room:${data.roomId}`, room);
    this.broadcastRoomSummary(room);
    return { room, participants: this.getParticipantCount(room.id), participantsInitials: this.getParticipantInitials(room.id) };
  }
}
