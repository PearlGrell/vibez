import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ConfigModule } from '@nestjs/config';
import environment from './config/app.config';
import { validate } from './config/environment.validator';
import { databaseConfig } from './config/db.config';
import { SearchModule } from './modules/search/search.module';
import { RoomsModule } from './modules/rooms/rooms.module';
import { SongsModule } from './modules/songs/songs.module';
import { ArtistsModule } from './modules/artists/artists.module';
import { AlbumsModule } from './modules/albums/albums.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [environment],
      validate,
    }),
    TypeOrmModule.forRootAsync(databaseConfig),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 20 }]),
    AuthModule,
    UsersModule,
    SearchModule,
    RoomsModule,
    SongsModule,
    ArtistsModule,
    AlbumsModule,
  ],
})
export class AppModule {}
