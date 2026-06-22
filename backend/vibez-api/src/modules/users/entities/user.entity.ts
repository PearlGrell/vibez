import { Column, CreateDateColumn, Entity, Index, PrimaryColumn, BeforeInsert, UpdateDateColumn, ManyToMany, JoinTable, OneToMany } from 'typeorm';
import { generateNanoId } from '../../../utils/nanoid';
import { Playlist } from './playlist.entity';
import { Song } from '../../songs/entities/song.entity';
import { Album } from '../../albums/entities/album.entity';
import { Room } from '../../rooms/entities/room.entity';
import { Artist } from '../../artists/entities/artist.entity';

@Entity('users')
export class User {
  @PrimaryColumn({ type: 'varchar', length: 11 })
  id: string;

  @BeforeInsert()
  generateId() {
    if (!this.id) {
      this.id = generateNanoId();
    }
  }

  @Column()
  name: string;

  @Index()
  @Column({
    unique: true,
  })
  email: string;

  @Index()
  @Column({
    unique: true,
    nullable: true
  })
  username: string;

  @Column({
    type: 'varchar',
    nullable: true,
  })
  profileUrl: string | null;

  @Column({
    type: 'varchar',
    nullable: true,
  })
  bio: string | null;

  @Column({
    type: 'text',
    array: true,
    default: '{}',
  })
  tags: string[];

  @Column({
    select: false,
  })
  password: string;
  
  @OneToMany(() => Playlist, (playlist) => playlist.createdBy)
  playlists: Playlist[];

  @ManyToMany(() => Playlist)
  @JoinTable({
    name: 'user_liked_playlists',
    joinColumn: {
      name: 'userId',
      referencedColumnName: 'id',
    },
    inverseJoinColumn: {
      name: 'playlistId',
      referencedColumnName: 'id',
    },
  })
  likedPlaylists: Playlist[];

  @ManyToMany(() => Artist)
  @JoinTable({
    name: 'user_followed_artists',
    joinColumn: {
      name: 'userId',
      referencedColumnName: 'id',
    },
    inverseJoinColumn: {
      name: 'artistId',
      referencedColumnName: 'id',
    },
  })
  followedArtists: Artist[];

  @ManyToMany(() => Song)
  @JoinTable({
    name: 'user_liked_songs',
    joinColumn: {
      name: 'userId',
      referencedColumnName: 'id',
    },
    inverseJoinColumn: {
      name: 'songId',
      referencedColumnName: 'id',
    },
  })
  likedSongs: Song[];

  @ManyToMany(() => Album)
  @JoinTable({
    name: 'user_liked_albums',
    joinColumn: {
      name: 'userId',
      referencedColumnName: 'id',
    },
    inverseJoinColumn: {
      name: 'albumId',
      referencedColumnName: 'id',
    },
  })
  likedAlbums: Album[];

  @ManyToMany(() => Room)
  @JoinTable({
    name: 'user_joined_rooms',
    joinColumn: {
      name: 'userId',
      referencedColumnName: 'id',
    },
    inverseJoinColumn: {
      name: 'roomId',
      referencedColumnName: 'id',
    },
  })
  joinedRooms: Room[];

  @ManyToMany(() => User, (user) => user.following)
  @JoinTable({
    name: 'user_followers',
    joinColumn: {
      name: 'userId',
      referencedColumnName: 'id',
    },
    inverseJoinColumn: {
      name: 'followerId',
      referencedColumnName: 'id',
    },
  })
  followers: User[];

  @ManyToMany(() => User, (user) => user.followers)
  following: User[];

  @Column({
    type: 'varchar',
    select: false,
    nullable: true,
  })
  otp: string | null;

  @Column({
    nullable: true,
    type: 'timestamptz',
    select: false,
  })
  otpExpiredAt: Date | null;

  @Column({
    nullable: true,
    type: 'timestamptz',
    select: false,
  })
  lastOtpSentAt: Date | null;

  @Column({
    default: 0
  })
  otpResendCount: number;

  @CreateDateColumn({
    type: 'timestamptz',
  })
  createdAt: Date;

  @UpdateDateColumn({
    type: 'timestamptz',
  })
  updatedAt: Date;
}
