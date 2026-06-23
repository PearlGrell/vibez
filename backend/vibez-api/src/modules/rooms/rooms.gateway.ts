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
import { RoomEvents } from './constants/room-events';
import {
  RoomJoinResponseDto,
  RoomLeaveResponseDto,
  RoomsResponseDto,
  RoomSyncResponseDto,
} from './dto/room-responses.dto';

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
        next();
      } catch {
        next(new Error('Authentication error'));
      }
    });
  }

  handleConnection(client: Socket) {}

  handleDisconnect(client: Socket) {}

  @SubscribeMessage(RoomEvents.ROOMS)
  async listRooms(
    @ConnectedSocket() client: Socket,
    @MessageBody() data?: { limit?: number },
  ): Promise<RoomsResponseDto> {
    const limit = data?.limit ?? 50;
    const rooms = await this.roomService.get(limit);

    return {
      rooms: rooms.map((room) => ({
        id: room.id,
        name: room.name,
        currentDj: room.currentDj,
        participants: this.server.sockets.adapter.rooms.get(`room:${room.id}`)?.size ?? 0,
        currentSongId: room.currentSong,
        playing: room.playing,
        startedAt: room.startedAt,
      })),
    };
  }

  @SubscribeMessage(RoomEvents.JOIN)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async joinRoom(@ConnectedSocket() client: Socket, @MessageBody() data: JoinRoomDto): Promise<RoomJoinResponseDto> {
    const room = await this.roomService.getActiveRoom(data.roomId);

    if (!room) {
      throw new WsException({ code: 'ROOM_NOT_FOUND', message: 'Room not found' });
    }

    const roomName = `room:${room.id}`;

    if (client.rooms.has(roomName)) {
      return {
        success: true,
        roomId: room.id,
        participants: this.server.sockets.adapter.rooms.get(roomName)?.size ?? 0,
        currentSong: room.currentSong,
        currentDj: room.currentDj,
        playing: room.playing,
        startedAt: room.startedAt,
      };
    }

    for (const r of client.rooms) {
      if (r.startsWith('room:') && r !== roomName) {
        await client.leave(r);
        const oldRoomId = r.replace('room:', '');
        await this.roomService.removeUserFromRoom(client.data.user.sub, oldRoomId);
        this.server.to(r).emit(RoomEvents.USER_LEFT, {
          userId: client.data.user.sub,
        });
      }
    }

    await client.join(roomName);
    await this.roomService.addUserToRoom(client.data.user.sub, room.id);

    this.server.to(roomName).emit(RoomEvents.USER_JOINED, {
      userId: client.data.user.sub,
    });

    return {
      success: true,
      roomId: room.id,
      participants: this.server.sockets.adapter.rooms.get(roomName)?.size ?? 0,
      currentSong: room.currentSong,
      currentDj: room.currentDj,
      playing: room.playing,
      startedAt: room.startedAt,
    };
  }

  @SubscribeMessage(RoomEvents.LEAVE)
  @UsePipes(new ZodPipe(leaveRoomSchema))
  async leaveRoom(@ConnectedSocket() client: Socket, @MessageBody() data: LeaveRoomDto): Promise<RoomLeaveResponseDto> {
    const room = await this.roomService.getActiveRoom(data.roomId);

    if (!room) {
      throw new WsException({ code: 'ROOM_NOT_FOUND', message: 'Room not found' });
    }

    await client.leave(`room:${room.id}`);
    await this.roomService.removeUserFromRoom(client.data.user.sub, room.id);

    this.server.to(`room:${room.id}`).emit(RoomEvents.USER_LEFT, {
      userId: client.data.user.sub,
    });

    return {
      success: true,
      roomId: room.id,
    };
  }

  @SubscribeMessage(RoomEvents.SYNC)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async syncRoom(@ConnectedSocket() client: Socket, @MessageBody() data: JoinRoomDto): Promise<RoomSyncResponseDto> {
    const room = await this.roomService.getActiveRoom(data.roomId);

    if (!room) {
      throw new WsException({ code: 'ROOM_NOT_FOUND', message: 'Room not found' });
    }

    return {
      participants: this.server.sockets.adapter.rooms.get(`room:${room.id}`)?.size ?? 0,
      currentSong: room.currentSong,
      currentDj: room.currentDj,
      playing: room.playing,
      startedAt: room.startedAt,
    };
  }
}
