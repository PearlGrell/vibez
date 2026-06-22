import { Column, Entity, JoinTable, ManyToMany, ManyToOne, PrimaryColumn, RelationId } from 'typeorm';
import { Album } from '../../albums/entities/album.entity';
import { Artist } from '../../artists/entities/artist.entity';
import { Playlist } from 'src/modules/users/entities/playlist.entity';

@Entity('songs')
export class Song {
  @PrimaryColumn()
  id: string;

  @Column()
  title: string;

  @Column()
  duration: number;

  @Column({ nullable: true })
  thumbnail: string;

  @Column({ nullable: true })
  year: string;

  @ManyToOne(() => Album, (album) => album.songs, { nullable: true, onDelete: 'SET NULL' })
  album: Album;

  @RelationId((song: Song) => song.album)
  albumId: string;

  @ManyToMany(() => Artist, (artist) => artist.songs)
  @JoinTable({
    name: 'song_artists',
    joinColumn: { name: 'songId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'artistId', referencedColumnName: 'id' },
  })
  artists: Artist[];
  
  @ManyToMany(() => Playlist, (playlist) => playlist.songs)
  playlists: Playlist[];
}
