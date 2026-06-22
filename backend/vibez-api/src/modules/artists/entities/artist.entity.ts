import { Column, Entity, PrimaryColumn, ManyToMany } from 'typeorm';
import { Album } from '../../albums/entities/album.entity';
import { Song } from '../../songs/entities/song.entity';

@Entity('artists')
export class Artist {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  thumbnail: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ nullable: true })
  subscribers: string;

  @Column({ nullable: true })
  views: string;

  @Column({ nullable: true })
  monthlyListeners: string;

  @ManyToMany(() => Song, (song) => song.artists)
  songs: Song[];

  @ManyToMany(() => Album, (album) => album.artists)
  albums: Album[];
}
