import { BeforeInsert, Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { Song } from 'src/modules/songs/entities/song.entity';
import { User } from 'src/modules/users/entities/user.entity';
import { Room } from './room.entity';
import { generateNanoId } from '../../../utils/nanoid';

@Entity('room_queue')
export class QueueItem {
  @PrimaryColumn({ type: 'varchar', length: 11 })
  id: string;

  @BeforeInsert()
  generateId() {
    if (!this.id) {
      this.id = generateNanoId();
    }
  }

  @ManyToOne(() => Room, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'roomId' })
  room: Room;

  @Column()
  roomId: string;

  @ManyToOne(() => Song, { eager: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'songId' })
  song: Song;

  @Column()
  songId: string;

  @ManyToOne(() => User, { eager: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'addedById' })
  addedBy: User;

  @Column()
  addedById: string;

  @Column({ default: 0 })
  position: number;

  @CreateDateColumn({ type: 'timestamptz' })
  addedAt: Date;
}
