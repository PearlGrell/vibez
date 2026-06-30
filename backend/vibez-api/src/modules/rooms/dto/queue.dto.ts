import z from 'zod';

export const addSongSchema = z.object({
  roomId: z.string(),
  songId: z.string(),
  requestedById: z.string().optional()
});

export type AddSongDto = z.infer<typeof addSongSchema>;

export const removeSongSchema = z.object({
  roomId: z.string(),
  queueItemId: z.string(),
});

export type RemoveSongDto = z.infer<typeof removeSongSchema>;

export const requestSongSchema = z.object({
  roomId: z.string(),
  songId: z.string(),
});

export type RequestSongDto = z.infer<typeof requestSongSchema>;

export const assignDjSchema = z.object({
  roomId: z.string(),
  userId: z.string(),
});

export type AssignDjDto = z.infer<typeof assignDjSchema>;
