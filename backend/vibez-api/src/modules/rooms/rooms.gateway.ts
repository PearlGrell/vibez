import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
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
  RoomSyncResponseDto,
} from './dto/room-responses.dto';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class RoomsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  constructor(
    private readonly roomService: RoomsService,
    private readonly jwtService: JwtService,
  ) {}

  @WebSocketServer()
  server: Server;

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth?.token;

      if (!token) {
        client.disconnect();
        return;
      }

      const payload = await this.jwtService.verifyAsync(token);

      client.data.user = payload;
    } catch {
      client.disconnect();
    }
  }

  async handleDisconnect(client: Socket) {
    if (client.data?.user?.sub) {
      await this.roomService.removeUserFromAllRooms(client.data.user.sub);
    }
  }

  @SubscribeMessage(RoomEvents.JOIN)
  @UsePipes(new ZodPipe(joinRoomSchema))
  async joinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: JoinRoomDto,
  ): Promise<RoomJoinResponseDto> {
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
        currentSongId: room.currentSong?.id,
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
      currentSongId: room.currentSong?.id,
      playing: room.playing,
      startedAt: room.startedAt,
    };
  }

  @SubscribeMessage(RoomEvents.LEAVE)
  @UsePipes(new ZodPipe(leaveRoomSchema))
  async leaveRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: LeaveRoomDto,
  ): Promise<RoomLeaveResponseDto> {
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
  async syncRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: JoinRoomDto,
  ): Promise<RoomSyncResponseDto> {
    const room = await this.roomService.getActiveRoom(data.roomId);

    if (!room) {
      throw new WsException({ code: 'ROOM_NOT_FOUND', message: 'Room not found' });
    }

    return {
      participants: this.server.sockets.adapter.rooms.get(`room:${room.id}`)?.size ?? 0,
      currentSongId: room.currentSong?.id,
      playing: room.playing,
      startedAt: room.startedAt,
    };
  }
}
