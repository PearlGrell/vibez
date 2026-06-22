import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleAsyncOptions } from '@nestjs/typeorm';
import { User } from 'src/modules/users/entities/user.entity';
import { Session } from 'src/modules/auth/entities/session.entity';
import { Room } from 'src/modules/rooms/entities/room.entity';
import { Artist } from 'src/modules/artists/entities/artist.entity';
import { Album } from 'src/modules/albums/entities/album.entity';
import { Song } from 'src/modules/songs/entities/song.entity';
import { Playlist } from 'src/modules/users/entities/playlist.entity';

export const databaseConfig: TypeOrmModuleAsyncOptions = {
  inject: [ConfigService],

  useFactory: (config: ConfigService) => ({
    type: 'postgres',

    host: config.get<string>('database.hostname'),
    port: config.get<number>('database.port'),

    username: config.get<string>('database.user'),
    password: config.get<string>('database.password'),
    database: config.get<string>('database.database'),

    entities: [User, Session, Room, Artist, Album, Song, Playlist],

    synchronize: config.get<string>('nodeEnv') !== 'production',

    ssl: config.get<boolean>('database.ssl') ? { rejectUnauthorized: false } : false,
  }),
};
