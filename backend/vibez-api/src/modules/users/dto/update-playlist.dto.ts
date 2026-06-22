import z from 'zod';

export const updatePlaylistSchema = z
  .object({
    name: z.string().optional(),
    description: z.string().optional().nullable(),
    thumbnail: z.string().optional(),
    tags: z.string().array().optional(),
    private: z.coerce.boolean().optional(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'At least one field must be provided',
  });

export type UpdatePlaylistDto = z.infer<typeof updatePlaylistSchema>;
