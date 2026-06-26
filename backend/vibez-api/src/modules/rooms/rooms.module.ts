import { Module } from '@nestjs/common';
import { RoomsService } from './rooms.service';
import { RoomsController } from './rooms.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Room } from './entities/room.entity';
import { QueueItem } from './entities/queue-item.entity';
import { User } from '../users/entities/user.entity';
import { SongsModule } from '../songs/songs.module';
import { AuthModule } from '../auth/auth.module';
import { JwtModule } from '@nestjs/jwt';
import { jwtConfig } from 'src/config/jwt.config';
import { RoomsGateway } from './rooms.gateway';

@Module({
  imports:[TypeOrmModule.forFeature([Room, QueueItem, User]), SongsModule, AuthModule, JwtModule.registerAsync(jwtConfig)],
  controllers: [RoomsController],
  providers: [RoomsService, RoomsGateway],
})
export class RoomsModule {}
