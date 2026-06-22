import z from "zod";

export const addSongSchema = z.object({
  songId: z.string(),
});

export type AddSongDto = z.infer<typeof addSongSchema>;
