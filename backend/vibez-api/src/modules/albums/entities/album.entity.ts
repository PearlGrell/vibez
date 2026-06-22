import { Column, Entity, JoinTable, ManyToMany, OneToMany, PrimaryColumn } from 'typeorm';
import { Artist } from '../../artists/entities/artist.entity';
import { Song } from '../../songs/entities/song.entity';

@Entity('albums')
export class Album {
  @PrimaryColumn()
  id: string;

  @Column()
  title: string;

  @Column({ nullable: true })
  type: string;

  @Column({ nullable: true })
  thumbnail: string;

  @Column({ default: false })
  isExplicit: boolean;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ nullable: true })
  year: string;

  @Column({ nullable: true })
  trackCount: number;

  @Column({ nullable: true })
  durationSeconds: number;

  @ManyToMany(() => Artist, (artist) => artist.albums)
  @JoinTable({
    name: 'album_artists',
    joinColumn: { name: 'albumId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'artistId', referencedColumnName: 'id' },
  })
  artists: Artist[];

  @OneToMany(() => Song, (song) => song.album)
  songs: Song[];
}
