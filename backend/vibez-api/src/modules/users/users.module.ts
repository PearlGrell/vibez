import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { Session } from '../auth/entities/session.entity';
import { PlaylistsModule } from './playlists/playlists.module';
import { AuthModule } from '../auth/auth.module';
import { JwtModule } from '@nestjs/jwt';
import { jwtConfig } from 'src/config/jwt.config';
import { Song } from '../songs/entities/song.entity';
import { Album } from '../albums/entities/album.entity';
import { Room } from '../rooms/entities/room.entity';
import { SongsModule } from '../songs/songs.module';
import { AlbumsModule } from '../albums/albums.module';
import { Playlist } from './entities/playlist.entity';
import { Artist } from '../artists/entities/artist.entity';
import { ArtistsModule } from '../artists/artists.module';
@Module({
  imports: [
    TypeOrmModule.forFeature([User, Session, Song, Album, Room, Playlist, Artist]),
    PlaylistsModule,
    AuthModule,
    JwtModule.registerAsync(jwtConfig),
    SongsModule,
    AlbumsModule,
    ArtistsModule,
  ],
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}

