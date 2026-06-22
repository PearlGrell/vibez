import z from "zod";

export const createPlaylistSchema = z.object({
    name: z.string(),
    description: z.string().optional().nullable(),
    thumbnail: z.string().optional().nullable(),
    tags: z.string().array(),
    private: z.coerce.boolean(),
})

export type CreatePlaylistDto = z.infer<typeof createPlaylistSchema>
