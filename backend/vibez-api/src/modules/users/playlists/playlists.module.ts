import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { jwtConfig } from 'src/config/jwt.config';
import { AuthModule } from '../../auth/auth.module';
import { SongsModule } from '../../songs/songs.module';
import { Playlist } from '../entities/playlist.entity';
import { Song } from '../../songs/entities/song.entity';
import { PlaylistsService } from './playlists.service';
import { PlaylistsController } from './playlists.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([Playlist, Song]),
    AuthModule,
    JwtModule.registerAsync(jwtConfig),
    SongsModule,
  ],
  controllers: [PlaylistsController],
  providers: [PlaylistsService],
  exports: [PlaylistsService],
})
export class PlaylistsModule {}
