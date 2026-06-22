import { Song } from 'src/modules/songs/entities/song.entity';
import { User } from 'src/modules/users/entities/user.entity';
import { Column, Entity, JoinColumn, ManyToOne, OneToOne, PrimaryColumn, BeforeInsert } from 'typeorm';
import { generateNanoId } from '../../../utils/nanoid';

@Entity('rooms')
export class Room {
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

  @Column()
  description: string;

  @Column({
    type: 'text',
    array: true,
  })
  tags: string[];

  @Column({
    default: false
  })
  private: boolean;

  @OneToOne(() => User, {
    nullable: true,
    onDelete: 'SET NULL',
  })
  @JoinColumn({
    name: 'currentDjId',
  })
  currentDj: User | null;

  @ManyToOne(() => User, {
    nullable: true,
    onDelete: 'CASCADE',
  })
  @JoinColumn({
    name: 'createdById',
  })
  createdBy: User | null;

  @Column({
    type: 'varchar',
    nullable: true,
  })
  createdById: string | null;

  @ManyToOne(() => Song, {
    nullable: true
  })
  @JoinColumn({
    name: 'currentSongId'
  })
  currentSong: Song | null

  @Column({
    type: 'timestamptz',
    nullable: true,
  })
  startedAt: Date | null;

  @Column({
    default: false
  })
  playing: boolean;

  @Column({
    type: 'timestamptz',
  })
  createdAt: Date;

  @Column({
    type: 'timestamptz',
  })
  updatedAt: Date;
}
