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
      const token = client.handshake.auth?.token ?? client.handshake.headers.authorization?.replace('Bearer ', '');

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

  @SubscribeMessage('room:join')
  async joinRoom(@ConnectedSocket() client: Socket, @MessageBody() body: string) {
    const data = JSON.parse(body);
    if (!data?.roomId) {
      throw new WsException('roomId is required');
    }

    const room = await this.roomService.getById(data.roomId);

    if (!room) {
      throw new WsException('Room not found');
    }

    await client.join(`room:${room.id}`);
    await this.roomService.addUserToRoom(client.data.user.sub, room.id);

    this.server.to(`room:${room.id}`).emit('room:user_joined', {
      userId: client.data.user.sub,
    });

    console.log(client.data)

    return {
      success: true,
      roomId: room.id,
      participants: this.server.sockets.adapter.rooms.get(`room:${room.id}`)?.size ?? 0,
      currentSongId: room.currentSong?.id,
      playing: room.playing,
      startedAt: room.startedAt
    };
  }

  @SubscribeMessage('room:leave')
  async leaveRoom(@ConnectedSocket() client: Socket, @MessageBody() body: string) {
    const data = JSON.parse(body);
    if (!data?.roomId) {
      throw new WsException('roomId is required');
    }

    const room = await this.roomService.getById(data.roomId);

    if (!room) {
      throw new WsException('Room not found');
    }

    await client.leave(`room:${room.id}`);
    await this.roomService.removeUserFromRoom(client.data.user.sub, room.id);

    this.server.to(`room:${room.id}`).emit('room:user_left', {
      userId: client.data.user.sub,
    });

    return {
      success: true,
      roomId: room.id,
    };
  }
}
