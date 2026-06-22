import { Column, Entity, JoinColumn, ManyToOne, PrimaryColumn, BeforeInsert, ManyToMany, JoinTable, RelationId } from 'typeorm';
import { User } from './user.entity';
import { generateNanoId } from '../../../utils/nanoid';
import { Song } from '../../songs/entities/song.entity';

@Entity('playlists')
export class Playlist {
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

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({
    type: 'varchar',
    nullable: true,
  })
  thumbnail: string | null;

  @Column({
    type: 'text',
    nullable: true,
    array: true,
  })
  tags: string[];

  @Column()
  private: boolean;

  @ManyToMany(() => Song, (song) => song.playlists)
  @JoinTable({
    name: 'playlist_songs',
    joinColumn: {
      name: 'playlistId',
      referencedColumnName: 'id',
    },
    inverseJoinColumn: {
      name: 'songId',
      referencedColumnName: 'id',
    },
  })
  songs: Song[];

  @RelationId((playlist: Playlist) => playlist.createdBy)
  createdById: string;

  @ManyToOne(() => User, (user) => user.playlists, { onDelete: 'CASCADE' })
  @JoinColumn({
    name: 'createdById',
  })
  createdBy: User;
}
